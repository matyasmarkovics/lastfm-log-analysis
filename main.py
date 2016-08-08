import falcon
from falcon_multipart.middleware import MultipartMiddleware
import pymysql.cursors
from contextlib import contextmanager
import csv
import tempfile
import os

@contextmanager
def mysql_connector():
    socket_path = os.path.dirname(os.path.realpath(__file__)) + '/mysql/_data/mysql.sock'
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


app = falcon.API(middleware=[MultipartMiddleware()])


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
                with mysql_connector() as connection:
                    with connection.cursor() as cursor:
                        tmpf.write(tsv.file.read())
                        tmpf.flush()

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
        if tsv.file:
            with mysql_connector() as connection:
                with connection.cursor() as cursor:
                    linecount = 0
                    tsv_reader = csv.reader(tsv.file, delimiter='\t')
                    for row in tsv_reader:
                        sql = """
                            INSERT IGNORE INTO log (username, artist, track, played_at)
                            VALUES (
                                %s, %s, %s,
                                REPLACE(REPLACE(%s, 'T', ' '), 'Z', '')
                            );
                        """
                        data = (row[0], row[3], row[5], row[1])
                        cursor.execute(sql, data)
                        linecount += 1
                    resp.status = falcon.HTTP_200
                    resp.body = "%s\n" % linecount


class UsersResource(DbTableResource):
    on_get_query = 'SELECT username FROM user;'


class TopUsersResource(DbTableResource):
    on_get_query = """
    SELECT username, COUNT(song_id)
    FROM play
    JOIN user USING (user_id)
    GROUP BY user_id
    ORDER BY 2 DESC
    LIMIT {limit};
    """

class TopSongsResource(DbTableResource):
    on_get_query = """
    SELECT CONCAT(artist, ' - ', track), COUNT(played_at)
    FROM play
    JOIN song USING (song_id)
    GROUP BY song_id
    ORDER BY 2 DESC
    LIMIT {limit};
    """

class TopSessionsResource(DbTableResource):
    on_get_query = """
    SELECT
        duration_s,
        username,
        COUNT(played_at),
        GROUP_CONCAT(CONCAT(artist, ' - ', track))
    FROM play
    JOIN user USING (user_id)
    JOIN song USING (song_id)
    JOIN session USING (session_id)
    GROUP BY session_id
    ORDER BY 1 DESC
    LIMIT {limit};
    """

app.add_route('/log/file', LogFileResource())
app.add_route('/log/memory', LogMemoryResource())
app.add_route('/users', UsersResource())
app.add_route('/play/top/{n}/users', TopUsersResource())
app.add_route('/play/top/{n}/songs', TopSongsResource())
app.add_route('/play/top/{n}/sessions', TopSessionsResource())

