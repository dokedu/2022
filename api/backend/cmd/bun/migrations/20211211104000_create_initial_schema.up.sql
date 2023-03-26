CREATE OR REPLACE FUNCTION nanoid(size int DEFAULT 21)
    RETURNS text AS
$$
DECLARE
    id          text     := '';
    i           int      := 0;
    urlAlphabet char(64) := 'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';
    bytes       bytea    := extensions.gen_random_bytes(size);
    byte        int;
    pos         int;
BEGIN
    WHILE i < size
        LOOP
            byte := get_byte(bytes, i);
            pos := (byte & 63) + 1; -- + 1 because substr starts at 1 for some reason
            id := id || substr(urlAlphabet, pos, 1);
            i = i + 1;
        END LOOP;
    RETURN id;
END
$$ LANGUAGE PLPGSQL STABLE;


CREATE TABLE public.identities
(
    id          text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    global_role text        NOT NULL CHECK ( global_role IN ('superadmin', 'default') ),
    created_at  timestamptz NOT NULL             DEFAULT current_timestamp,
    user_id     uuid        NOT NULL UNIQUE,
    deleted_at  timestamptz NULL                 DEFAULT NULL
);
create index on public.identities (deleted_at) where deleted_at is null;

CREATE TABLE public.addresses
(
    id         text                     NOT NULL PRIMARY KEY DEFAULT nanoid(),
    street     text                     NOT NULL,
    zip        text                     NOT NULL,
    city       text                     NOT NULL,
    state      text                     NOT NULL,
    country    text                     NOT NULL,
    created_at timestamptz              NOT NULL             DEFAULT current_timestamp,
    deleted_at timestamptz              NULL                 DEFAULT NULL
);
create index on public.addresses (deleted_at) where deleted_at is null;

CREATE TABLE public.organisations
(
    id         text                     NOT NULL PRIMARY KEY DEFAULT nanoid(),
    name       text                     NOT NULL,
    address_id text                     NOT NULL REFERENCES addresses (id),
    legal_name text                     NOT NULL,
    website    text                     NOT NULL,
    phone      text                     NOT NULL,
    owner_id   text                     NOT NULL REFERENCES identities (id),
    created_at timestamptz              NOT NULL             DEFAULT current_timestamp,
    deleted_at timestamptz              NULL                 DEFAULT NULL
);
create index on public.organisations (deleted_at) where deleted_at is null;

CREATE TABLE public.accounts
(
    id                    text                     NOT NULL PRIMARY KEY DEFAULT nanoid(),
    role                  text                     NOT NULL CHECK ( role in ('owner', 'admin', 'teacher', 'teacher_guest', 'student') ),
    identity_id           text                     NULL REFERENCES public.identities (id),
    organisation_id       text                     NOT NULL REFERENCES public.organisations (id),
    first_name            text                     NOT NULL,
    last_name             text                     NOT NULL,
    avatar_file_bucket_id text                     NULL,
    avatar_file_name      text                     NULL,
    created_at            timestamptz              NOT NULL             DEFAULT current_timestamp,
    deleted_at            timestamptz              NULL                 DEFAULT NULL,
    joined_at             timestamptz              NULL                 DEFAULT NULL,
    left_at               timestamptz              NULL                 DEFAULT NULL,

    FOREIGN KEY (avatar_file_bucket_id, avatar_file_name) REFERENCES storage.objects (bucket_id, name)
);
create index on public.accounts using hash (identity_id);
create index on public.accounts (role);
create index on public.accounts (deleted_at) where deleted_at is null;

-- auth helper functions
CREATE OR REPLACE FUNCTION identity_id()
    RETURNS text
    LANGUAGE sql
AS
$$
SELECT id
FROM public.identities
WHERE user_id = auth.uid()
  and deleted_at is null
LIMIT 1;
$$;

create or replace function identity_account_ids() returns setof text
    language sql
    set search_path = public security definer as
$$
with _iid as (select identity_id())
select id
from public.accounts
where identity_id = (select * from _iid)
  and deleted_at is null
$$;

create or replace function identity_account_ids_role(_roles text[]) returns setof text
    language sql
    set search_path = public security definer as
$$
with _iid as (select identity_id())
select id
from public.accounts a
where a.identity_id = (select * from _iid)
  and a.role = any (_roles)
  and a.deleted_at is null
$$;

create or replace function identity_organisation_ids() returns setof text
    language sql
    set search_path = public security definer as
$$
with _iid as (select identity_id())
select organisation_id
from public.accounts
where identity_id = (select * from _iid)
  and deleted_at is null
$$;

create or replace function identity_organisation_ids_role(_roles text[]) returns setof text
    language sql
    set search_path = public security definer as
$$
with _iid as (select identity_id())
select organisation_id
from public.accounts a
where a.identity_id = (select * from _iid)
  and a.role = any (_roles)
  and a.deleted_at is null
$$;


CREATE TABLE public.entries
(
    id         text                     NOT NULL PRIMARY KEY DEFAULT nanoid(),
    date       date                     NOT NULL,
    body       jsonb                    NOT NULL,
    account_id text                     NOT NULL REFERENCES public.accounts (id),
    created_at timestamptz              NOT NULL             DEFAULT current_timestamp,
    deleted_at timestamptz              NULL                 DEFAULT NULL
);
create index on public.entries (deleted_at) where deleted_at is null;
create index on public.entries (created_at nulls last);

CREATE TABLE public.entry_accounts
(
    id         text                     NOT NULL PRIMARY KEY DEFAULT nanoid(),
    entry_id   text                     NOT NULL REFERENCES public.entries (id),
    account_id text                     NOT NULL REFERENCES public.accounts (id),
    created_at timestamptz              NOT NULL             DEFAULT current_timestamp,
    deleted_at timestamptz              NULL                 DEFAULT NULL
);
CREATE INDEX ON public.entry_accounts (entry_id, account_id);
create index on public.entry_accounts (deleted_at) where deleted_at is null;

CREATE TABLE public.competences
(
    id              text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    name            text        not null,
    competence_id   text        NULL,
    competence_type text        NOT NULL CHECK ( competence_type in ('subject', 'group', 'competence') ),
    organisation_id text        NOT NULL,
    grades          int[]       NOT NULL,
    color           text        NULL,
    curriculum_id   text        NULL,
    created_at      timestamptz NOT NULL             DEFAULT current_timestamp,
    deleted_at      timestamptz NULL                 DEFAULT NULL
);
CREATE INDEX competences_type on public.competences using hash (competence_type);
CREATE INDEX ON public.competences (competence_id, competence_type);
create index on public.competences (deleted_at) where deleted_at is null;

CREATE TABLE public.entry_account_competences
(
    id            text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    level         int         NOT NULL CHECK ( level <= 3 and level >= 0),
    account_id    text        NOT NULL REFERENCES public.accounts (id),
    entry_id      text        NOT NULL REFERENCES public.entries (id),
    competence_id text        NOT NULL REFERENCES public.competences (id),
    created_at    timestamptz NOT NULL             DEFAULT current_timestamp,
    deleted_at    timestamptz NULL                 DEFAULT NULL,
    UNIQUE (account_id, entry_id, competence_id)
);
create index on public.entry_account_competences (deleted_at) where deleted_at is null;

CREATE TABLE public.entry_files
(
    id             text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    entry_id       text        NOT NULL REFERENCES public.entries (id),
    file_bucket_id text        NOT NULL,
    file_name      text        NOT NULL,
    created_at     timestamptz NOT NULL             DEFAULT current_timestamp,
    deleted_at     timestamptz NULL                 DEFAULT NULL,
    FOREIGN KEY (file_bucket_id, file_name) REFERENCES storage.objects (bucket_id, name),

    UNIQUE (entry_id, file_bucket_id, file_name)
);
create index on public.entry_files (deleted_at) where deleted_at is null;

CREATE TABLE public.events
(
    id                   text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    image_file_bucket_id text        NULL,
    image_file_name      text        NULL,
    organisation_id      text        NOT NULL REFERENCES organisations (id),
    title                text        not null,
    body                 text        NOT NULL,
    starts_at            timestamptz NOT NULL,
    ends_at              timestamptz NOT NULL,
    recurrence           text[]      NULL                 DEFAULT NULL,
    created_at           timestamptz NOT NULL             DEFAULT current_timestamp,
    deleted_at           timestamptz NULL                 DEFAULT NULL,

    FOREIGN KEY (image_file_bucket_id, image_file_name) REFERENCES storage.objects (bucket_id, name)
);
create index on public.events (deleted_at) where deleted_at is null;

CREATE TABLE public.entry_events
(
    id         text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    entry_id   text        NOT NULL REFERENCES entries (id),
    event_id   text        NOT NULL REFERENCES events (id),
    created_at timestamptz NOT NULL             DEFAULT current_timestamp,
    deleted_at timestamptz NULL                 DEFAULT NULL
);
create index on public.entry_events (deleted_at) where deleted_at is null;

CREATE TABLE public.reports
(
    id                 text        NOT NULL                                                  DEFAULT nanoid(),
    file_bucket_id     text        NULL,
    file_name          text        NULL,
    status             text        NOT NULL CHECK ( status in ('pending', 'done', 'error') ) DEFAULT 'pending',
    type               text        NOT NULL CHECK (type in ('report', 'subjects')),

    "from"             timestamptz NOT NULL,
    "to"               timestamptz NOT NULL,

    account_id         text        NOT NULL REFERENCES accounts (id),
    student_account_id text        NOT NULL REFERENCES accounts (id),
    meta               jsonb       NULL,
    created_at         timestamptz NOT NULL                                                  DEFAULT current_timestamp,
    deleted_at         timestamptz NULL                                                      DEFAULT NULL,

    FOREIGN KEY (file_bucket_id, file_name) REFERENCES storage.objects (bucket_id, name),
    check (
            (status in ('pending', 'error') and file_bucket_id is null and file_name is null) or
            (status in ('done') and file_bucket_id is not null and file_name is not null)
        )
);
create index on public.reports (deleted_at) where deleted_at is null;

CREATE TABLE public.event_competences
(
    id            text PRIMARY KEY     DEFAULT nanoid(),
    event_id      text        NOT NULL REFERENCES events (id),
    competence_id text        NOT NULL REFERENCES competences (id),
    created_at    timestamptz NOT NULL DEFAULT current_timestamp,
    deleted_at    timestamptz NULL     DEFAULT NULL
);
create index on public.event_competences (deleted_at) where deleted_at is null;