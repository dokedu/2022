SET statement_timeout = 0;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION nanoid(size int DEFAULT 21)
    RETURNS text AS
$$
DECLARE
    id          text     := '';
    i           int      := 0;
    urlalphabet char(64) := 'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';
    bytes       bytea    := gen_random_bytes(size);
    byte        int;
    pos         int;
BEGIN
    WHILE i < size
        LOOP
            byte := GET_BYTE(bytes, i);
            pos := (byte & 63) + 1; -- + 1 because substr starts at 1 for some reason
            id := id || SUBSTR(urlalphabet, pos, 1);
            i = i + 1;
        END LOOP;
    RETURN id;
END
$$ LANGUAGE plpgsql STABLE;

CREATE TABLE organisations
(
    id         text        DEFAULT nanoid() NOT NULL PRIMARY KEY,
    name       text                         NOT NULL,
    owner_id   text                         NOT NULL,
    created_at timestamptz DEFAULT NOW()    NOT NULL,
    deleted_at timestamptz
);

CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');

CREATE TABLE users
(
    id              text        DEFAULT nanoid() NOT NULL PRIMARY KEY,
    role            user_role                    NOT NULL,
    organisation_id text                         NOT NULL REFERENCES organisations,
    name            text                         NOT NULL,
    email           text                         NOT NULL,
    password        text                         NOT NULL,
    created_at      timestamptz DEFAULT NOW()    NOT NULL,
    deleted_at      timestamptz
);

ALTER TABLE organisations
    ADD FOREIGN KEY (owner_id) REFERENCES users (id);

CREATE TABLE tasks
(
    id              text        DEFAULT nanoid() NOT NULL PRIMARY KEY,
    name            text                         NOT NULL,
    description     text                         NOT NULL,
    user_id         text                         NOT NULL REFERENCES users,
    organisation_id text                         NOT NULL REFERENCES organisations,
    created_at      timestamptz DEFAULT NOW()    NOT NULL,
    deleted_at      timestamptz
);

