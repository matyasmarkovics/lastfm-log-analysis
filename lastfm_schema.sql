CREATE SCHEMA lastfm
    DEFAULT CHARACTER SET utf8;

USE lastfm;

CREATE TABLE log (
    log_id INT(11) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    played_at TIMESTAMP NOT NULL,
    artist VARCHAR(255) NOT NULL,
    track VARCHAR(255) NOT NULL,

    CONSTRAINT uc_user_played UNIQUE (username, played_at)
) ENGINE=InnoDB AUTO_INCREMENT = 1;
    
CREATE TABLE user (
    user_id INT(11) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE KEY
) ENGINE=InnoDB AUTO_INCREMENT = 1;

CREATE TABLE song (
    song_id INT(11) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    artist VARCHAR(255) NOT NULL,
    track VARCHAR(255) NOT NULL,

    CONSTRAINT uc_artist_track UNIQUE KEY (artist, track) 
) ENGINE=InnoDB AUTO_INCREMENT = 1;

CREATE TABLE session (
    session_id INT(11) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    duration_s INT(11) UNSIGNED NOT NULL DEFAULT 0,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT = 1;

CREATE TABLE play (
    play_id INT(11) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    user_id INT(11) UNSIGNED NOT NULL,
    played_at TIMESTAMP NOT NULL,
    song_id INT(11) UNSIGNED NOT NULL,
    session_id INT(11) UNSIGNED NOT NULL,

    INDEX (user_id),
    INDEX (song_id),
    INDEX (session_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (song_id) REFERENCES song(song_id),
    FOREIGN KEY (session_id) REFERENCES session(session_id)
) ENGINE=InnoDB AUTO_INCREMENT = 1;


DELIMITER $$

CREATE TRIGGER log_to_played_song
    AFTER INSERT ON log FOR EACH ROW
    BEGIN
        DECLARE existing_session_id INT(11) UNSIGNED;
        
        INSERT IGNORE INTO user
        SET username = NEW.username;
        
        INSERT IGNORE INTO song
        SET artist = NEW.artist,
            track = NEW.track;
        
        SELECT session_id INTO existing_session_id
        FROM play
        JOIN user USING (user_id)
        WHERE username = NEW.username
            AND played_at BETWEEN
                NEW.played_at - INTERVAL 20 MINUTE
                AND
                NEW.played_at + INTERVAL 20 MINUTE
        GROUP BY session_id;

        IF existing_session_id IS NULL THEN
            INSERT INTO session
            SET started_at = NEW.played_at,
                ended_at = NEW.played_at;
            SELECT LAST_INSERT_ID() INTO existing_session_id;
        ELSE
            UPDATE session
            SET session.started_at = LEAST(NEW.played_at, session.started_at),
                session.ended_at = GREATEST(NEW.played_at, session.ended_at),
                session.duration_s = TIMESTAMPDIFF(
                    SECOND,
                    LEAST(NEW.played_at, session.started_at),
                    GREATEST(NEW.played_at, session.ended_at)) 
            WHERE session.session_id = existing_session_id;
        END IF;

        INSERT INTO play
        SET user_id = (SELECT user_id FROM user
                        WHERE username = NEW.username),
            played_at = NEW.played_at,
            song_id = (SELECT song_id FROM song
                        WHERE artist = NEW.artist
                            AND track = NEW.track),
            session_id = existing_session_id;
                            
    END$$

DELIMITER ;


-- DEFAULT CHARSET=utf8 COLLATE=utf8_bin
