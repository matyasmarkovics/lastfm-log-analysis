-- Start a transaction.
BEGIN;

-- Plan the tests.
SELECT tap.plan(3);

LOAD DATA LOCAL INFILE '_test/30b9cdb95aecb5981749/testdata.tsv'
INTO TABLE lastfm.log
FIELDS TERMINATED BY '\t'
(username, played_at, @dummy, artist, @dummy, track);

-- Run the tests.
SELECT tap.eq( COUNT(*), 2, 'users saved' )
FROM lastfm.user;

SELECT tap.eq( COUNT(*), 8, 'songs saved' )
FROM lastfm.song;

SELECT tap.eq( COUNT(*), 10, 'All `log` entries saved to `play`' )
FROM lastfm.play;

-- Finish the tests and clean up.
CALL tap.finish();
ROLLBACK;
