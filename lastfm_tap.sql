-- Start a transaction.
BEGIN;

-- Plan the tests.
SELECT tap.plan(4);

LOAD DATA LOCAL INFILE '_test/30b9cdb95aecb5981749/testdata.tsv'
INTO TABLE lastfm.log
FIELDS TERMINATED BY '\t'
(username, played_at, @dummy, artist, @dummy, track);

-- Run the tests.
SELECT tap.eq( COUNT(DISTINCT username), 2, 'users saved' )
FROM lastfm.log;

SELECT tap.eq( COUNT(DISTINCT artist, track), 8, 'songs saved' )
FROM lastfm.log;


CALL lastfm.create_user_sessions('Ted');
CALL lastfm.create_user_sessions('Uri');
SELECT tap.eq( COUNT(DISTINCT session_uuid), 6, 'sessions identified' )
FROM lastfm.log;

SELECT tap.eq( COUNT(*), 10, 'All `log` entries saved' )
FROM lastfm.log;

-- Finish the tests and clean up.
CALL tap.finish();
-- ROLLBACK;
