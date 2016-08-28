CREATE SCHEMA lastfm
    DEFAULT CHARACTER SET utf8;

USE lastfm;

CREATE TABLE log (
    log_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    played_at TIMESTAMP NOT NULL DEFAULT 0,
    artist VARCHAR(255) NOT NULL,
    track VARCHAR(255) NOT NULL,
    duplicate TINYINT UNSIGNED NOT NULL DEFAULT 0,
    session_uuid BIGINT UNSIGNED,
    INDEX (username),
    INDEX (artist, track),
    INDEX (played_at),
    INDEX (session_uuid),

    CONSTRAINT uc_user_played_artist_track UNIQUE (username, played_at, artist, track)
) ENGINE=InnoDB AUTO_INCREMENT = 1;


DELIMITER &&

CREATE PROCEDURE create_user_sessions (IN username_in VARCHAR(255))
BEGIN
    DECLARE latest_session_uuid BIGINT UNSIGNED DEFAULT UUID_SHORT();
    DECLARE latest_played_at TIMESTAMP DEFAULT '1970-01-01 00:00:00';
    
    DECLARE current_log_id INT UNSIGNED;
    DECLARE current_played_at TIMESTAMP;

    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR SELECT log_id, played_at FROM log
                            WHERE username = username_in
                            ORDER BY played_at ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO current_log_id, current_played_at;
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF current_played_at > latest_played_at + INTERVAL 20 MINUTE THEN
            SELECT UUID_SHORT() INTO latest_session_uuid;
        END IF;

        UPDATE log SET session_uuid = latest_session_uuid
        WHERE log_id = current_log_id;

        SELECT current_played_at INTO latest_played_at;
    END LOOP;
    CLOSE cur;

END&&

DELIMITER ;
