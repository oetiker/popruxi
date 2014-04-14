CREATE TABLE uidmap (
     user TEXT,
     uid_new TEXT,
     uid_old TEXT,
     hash TEXT
);
CREATE INDEX uid_new_idx ON uidmap (user,uid_new);
CREATE INDEX hash_idx ON uidmap (user,hash);
CREATE INDEX uid_old_idx ON uidmap (user,uid_old);
