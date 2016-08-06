CREATE SCHEMA lastfm
    DEFAULT CHARACTER SET utf8;

USE lastfm;

CREATE TABLE log (
    log_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    played_at TIMESTAMP NOT NULL,
    artist VARCHAR(255) NOT NULL,
    track VARCHAR(255) NOT NULL,

    CONSTRAINT uc_user_played UNIQUE (username, played_at)
) ENGINE=InnoDB AUTO_INCREMENT = 1;
    
CREATE TABLE user (
    user_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE KEY
) ENGINE=InnoDB AUTO_INCREMENT = 1;

CREATE TABLE song (
    song_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    artist VARCHAR(255) NOT NULL,
    track VARCHAR(255) NOT NULL,

    CONSTRAINT uc_artist_track UNIQUE KEY (artist, track) 
) ENGINE=InnoDB AUTO_INCREMENT = 1;

CREATE TABLE play (
    play_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    user_id INT(11) NOT NULL,
    played_at TIMESTAMP NOT NULL,
    song_id INT(11) NOT NULL,
    -- session_id INT(11) DEFAULT NULL,

    INDEX (user_id),
    INDEX (song_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (song_id) REFERENCES song(song_id)
) ENGINE=InnoDB AUTO_INCREMENT = 1;

DELIMITER ||

CREATE TRIGGER log_to_played_song
    AFTER INSERT ON log FOR EACH ROW
    BEGIN
        INSERT IGNORE INTO user
        SET username = NEW.username;
        
        INSERT IGNORE INTO song
        SET artist = NEW.artist,
            track = NEW.track;
        
        INSERT INTO play
        SET user_id = (SELECT user_id FROM user
                        WHERE username = NEW.username),
            played_at = NEW.played_at,
            song_id = (SELECT song_id FROM song
                        WHERE artist = NEW.artist
                            AND track = NEW.track);
                            
    END||

DELIMITER ;


-- DEFAULT CHARSET=utf8 COLLATE=utf8_bin
