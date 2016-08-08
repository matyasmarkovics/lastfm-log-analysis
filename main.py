import falcon
from falcon_multipart.middleware import MultipartMiddleware
import pymysql.cursors
from contextlib import contextmanager
import csv
import tempfile
import os

@contextmanager
def mysql_connector():
    # Connect to the database
    connection = pymysql.connect(unix_socket='/private/tmp/mysql.sock',
                                 user='root',
                                 #password='passwd',
                                 host='localhost',
                                 database='lastfm',
                                 charset='utf8mb4',
                                 cursorclass=pymysql.cursors.DictCursor,
                                 autocommit=True,
                                 local_infile=True)
    try:
        yield connection
    finally:
        connection.close()


# falcon.API instances are callable WSGI apps
app = falcon.API(middleware=[MultipartMiddleware()])

# Falcon follows the REST architectural style, meaning (among
# other things) that you think in terms of resources and state
# transitions, which map to HTTP verbs.
class ThingsResource(object):

    def on_post(self, req, resp, **kwargs):
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

                        linecount = 0
                        #tsv_reader = csv.reader(tsv.file, delimiter='\t')
                        #for row in tsv_reader:
                        #    # Create a new record
                        #    sql = """
                        #        INSERT IGNORE INTO log (username, artist, track, played_at)
                        #        VALUES (
                        #            %s, %s, %s,
                        #            REPLACE(REPLACE(%s, 'T', ' '), 'Z', '')
                        #        );
                        #    """
                        #    data = (row[0], row[3], row[5], row[1])
                        #    #print cursor.mogrify(sql, data)
                        #    cursor.execute(sql, data)
                        #    linecount += 1
                        resp.status = falcon.HTTP_200
                        resp.body = "%s\n" % linecount


    def on_get(self, req, resp):
        with mysql_connector() as connection:
            with connection.cursor() as cursor:
                sql = "SELECT * FROM user;"
                cursor.execute(sql)
                fmt = lambda l: '\t'.join(['%s'] * len(l)) % tuple(l)
                resp.body = '\n'.join([fmt(r.values()) for r in cursor])
                resp.status = falcon.HTTP_200


# Resources are represented by long-lived class instances
# things will handle all requests to the '/things' URL path
app.add_route('/things', ThingsResource())
