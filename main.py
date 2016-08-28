import falcon
from falcon_multipart.middleware import MultipartMiddleware
import pymysql.cursors
from pymysql.err import InternalError
from contextlib import contextmanager
import tempfile
import os
from multiprocessing import Pool
import sys
import random
import cgi
import re


@contextmanager
def mysql_connector():
    socket_path = os.path.dirname(os.path.realpath(__file__)) + '/_data/mysql.sock'
    connection = pymysql.connect(unix_socket=socket_path,
                                 user='root',
                                 #password='passwd',
                                 host='localhost',
                                 database='lastfm',
                                 charset='utf8mb4',
                                 autocommit=True,
                                 local_infile=True)
    try:
        yield connection
    finally:
        connection.close()

def gen_cursor():
    with mysql_connector() as connection:
        with connection.cursor() as cursor:
            yield cursor

g_gen_cursor = None
def init_worker():
    global g_cursor, g_gen_cursor
    if not g_gen_cursor:
        g_gen_cursor = gen_cursor()
    g_cursor = next(g_gen_cursor)


def parse(line):
    row = re.split('\t', line.strip())
    data = (row[0], row[3], row[5], row[1])
    if random.randint(1, 5000) == 10:
        print "insert(%s, %s, %s, %s)" % data
    return data

def insert(args):
    stmt = """
        INSERT INTO log (username, artist, track, played_at)
        VALUES {}
        ON DUPLICATE KEY UPDATE duplicate = duplicate + 1;
    """
    values = ["(%s, %s, %s, REPLACE(REPLACE(%s, 'T', ' '), 'Z', ''))"]
    data = []
    for line in args:
        try:
            data.extend(parse(line))
        except IndexError:
            print "cannot parse line: %s" % line

    sql = stmt.format(',\n'.join(values * (len(data)/4)))

    retry_count = 0
    while retry_count < 3:
        try:
            inserted = g_cursor.execute(sql, data)
            return inserted
        except InternalError as ie:
            retry_count += 1
            if retry_count > 3:
                raise ie

def create_user_sessions(user):
    return g_cursor.callproc('create_user_sessions', user)

global pool
pool = Pool(int(os.environ['DB_INSERT_POOL_WORKERS']), init_worker)

class FileList(list):

    def read(self):
        return self

    def seek(self, position):
        pass

    def write(self, item):
        self.append(item)


class Parser(cgi.FieldStorage):
    chunk_size = int(os.environ['DB_INSERT_POOL_CHUNK_SIZE'])
    workers = int(os.environ['DB_INSERT_POOL_WORKERS'])
    task_buffer_size = workers * chunk_size

    def _FieldStorage__write(self, line):
        if not isinstance(self.file, FileList):
            self.file = FileList()
        if not isinstance(self._FieldStorage__file, list):
            self._FieldStorage__file = []

        self._FieldStorage__file.append(line)
        if len(self._FieldStorage__file) >= self.task_buffer_size:
            self.force_write()

    def force_write(self):
        if len(self._FieldStorage__file):
            tasks = [self._FieldStorage__file] \
                if self.workers >= len(self._FieldStorage__file) \
                else [ self._FieldStorage__file[i::self.workers]
                        for i in range(self.workers)
                        if len(self._FieldStorage__file[i::self.workers]) > 0 ]
            self.file.append(pool.map_async(insert, tasks, 1))
            self._FieldStorage__file = []

    def get_all(self, wrapper=None):
        if not wrapper:
            wrapper = lambda x: x
        self.force_write()
        return wrapper([wrapper([mr or 0 for mr in ar.get()]) for ar in self.file])


app = falcon.API(middleware=[MultipartMiddleware(parser=Parser)])


class DbTableResource(object):
    on_get_query = ''

    def on_get(self, req, resp, n=None):
        query = self.on_get_query.format(limit=n) if n else None
        with mysql_connector() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query or self.on_get_query)
                fmt = lambda l: '\t'.join(['%s'] * len(l)) % l
                resp.body = fmt(tuple([d[0] for d in cursor.description]))
                resp.body += '\n'
                resp.body += '\n'.join([fmt(r) for r in cursor])
                resp.body += '\n'
                resp.status = falcon.HTTP_200


class LogFileResource(DbTableResource):
    on_get_query = 'SELECT * FROM log;'

    def on_post(self, req, resp):
        tsv = req.get_param('tsv')
        if tsv.file:
            with tempfile.NamedTemporaryFile() as tmpf:
                tmpf.write(tsv.file.read())
                tmpf.flush()
                with mysql_connector() as connection:
                    with connection.cursor() as cursor:
                        sql = """
                        LOAD DATA LOCAL INFILE %s
                        INTO TABLE log
                        FIELDS TERMINATED BY '\t'
                        (username, played_at, @dummy, artist, @dummy, track);
                        """
                        cursor.execute(sql, (tmpf.name))
                        resp.status = falcon.HTTP_200


class LogMemoryResource(DbTableResource):
    on_get_query = 'SELECT * FROM log;'

    def on_post(self, req, resp):
        tsv = req.get_param('tsv')
        total_rows = tsv.get_all(wrapper=sum)
        resp.body = "%s\n" % total_rows
        resp.status = falcon.HTTP_200



class LogResource(LogMemoryResource):
    def on_delete(self, req, resp):
        with mysql_connector() as connection:
            with connection.cursor() as cursor:
                sql = """
                TRUNCATE log;
                """
                cursor.execute(sql)
                resp.status = falcon.HTTP_200


class UsersResource(DbTableResource):
    on_get_query = 'SELECT DISTINCT username FROM log;'


class TopUsersResource(DbTableResource):
    on_get_query = """
    SELECT username, COUNT(DISTINCT artist, track)
    FROM log
    GROUP BY username
    ORDER BY 2 DESC
    LIMIT {limit};
    """

class TopSongsResource(DbTableResource):
    on_get_query = """
    SELECT CONCAT(artist, ' - ', track), COUNT(played_at)
    FROM log
    GROUP BY artist, track
    ORDER BY 2 DESC
    LIMIT {limit};
    """


class TopSessionsResource(DbTableResource):
    on_get_query = """
    SELECT
        username,
        TIMESTAMPDIFF(SECOND, MIN(played_at), MAX(played_at)) AS duration_s,
        COUNT(played_at) AS size,
        GROUP_CONCAT(CONCAT(artist, ' - ', track)) AS songs
    FROM log
    GROUP BY session_uuid
    ORDER BY 2 DESC
    LIMIT {limit};
    """

    def on_get(self, req, resp, n=None):
        with mysql_connector() as connection:
            with connection.cursor() as cursor:
                cursor.execute(UsersResource.on_get_query)
                for _ in pool.imap_unordered(create_user_sessions, cursor):
                    pass
                cursor.execute(self.on_get_query.format(limit=n))
                fmt = lambda l: '\t'.join(['%s'] * len(l)) % l
                resp.body = fmt(tuple([d[0] for d in cursor.description]))
                resp.body += '\n'
                resp.body += '\n'.join([fmt(r) for r in cursor])
                resp.body += '\n'
                resp.status = falcon.HTTP_200

app.add_route('/log', LogResource())
app.add_route('/log/file', LogFileResource())
app.add_route('/log/memory', LogMemoryResource())
app.add_route('/users', UsersResource())
app.add_route('/play/top/{n}/users', TopUsersResource())
app.add_route('/play/top/{n}/songs', TopSongsResource())
app.add_route('/play/top/{n}/sessions', TopSessionsResource())

