-- generated fileCREATE OR REPLACE FUNCTION nanoid(size int DEFAULT 21)
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
create index on public.event_competences (deleted_at) where deleted_at is null;revoke all on bun_migrations from anon;
revoke all on bun_migrations from authenticated;
revoke all on bun_migration_locks from anon;
revoke all on bun_migration_locks from authenticated;

alter table public.organisations
    enable row level security;
alter table public.identities
    enable row level security;
alter table public.accounts
    enable row level security;
alter table public.entries
    enable row level security;
alter table public.entry_accounts
    enable row level security;
alter table public.competences
    enable row level security;
alter table public.entry_account_competences
    enable row level security;
alter table public.entry_files
    enable row level security;
alter table public.events
    enable row level security;
alter table public.entry_events
    enable row level security;
alter table public.reports
    enable row level security;
alter table public.addresses
    enable row level security;
alter table public.event_competences
    enable row level security;


create policy "users can get their identities"
    on public.identities for select
    using (user_id = auth.uid());

create policy "identities can get their organisations"
    on public.organisations for select
    using (id in (select identity_organisation_ids()));

create policy "identities can get their accounts"
    on public.accounts for select
    using (id in (select identity_account_ids()));


create policy "owner,admin can crud accounts in their organisations"
    on public.accounts for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])));

create policy "everyone can read accounts in their organisations"
    on public.accounts for select
    using (organisation_id in (select identity_organisation_ids()));

create or replace function is_allowed_to_crud_entry(_entry_account_id text) returns bool
    security definer set search_path = 'public'
    language plpgsql as
$$
declare
    _author accounts;
begin
    -- get the organisation of the entry
    select a.* into _author from accounts a where a.id = _entry_account_id limit 1;

    -- check if the user is the author of the entry
    if (_author.id in (select identity_account_ids_role('{owner, admin, teacher}'::text[]))) then
        return true;
    end if;

    -- check if the user is owner or admin in the organisation
    if (_author.organisation_id in (select identity_organisation_ids_role('{owner, admin}'::text[]))) then
        return true;
    end if;

    return false;
end;
$$;

create policy "entires_rls" on public.entries for all
    using (is_allowed_to_crud_entry(account_id))
    with check (is_allowed_to_crud_entry(account_id));

--todo: might be insecure for teacher
create policy "owner,admin,teacher can manage entry_accounts"
    on public.entry_accounts for all
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
    using (
        account_id in
        (select id
         from accounts a
         where a.id = entry_accounts.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    )
    with check (
        account_id in
        (select id
         from accounts a
         where a.id = entry_accounts.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    );

create policy "everyone can read competences"
    on public.competences for select
    using (organisation_id in (select identity_organisation_ids()));

create policy "owner,admin can crud competences"
    on public.competences for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])));

-- todo insecure for teacher
create policy "owner,admin,teacher can manage entry_account_competences"
    on public.entry_account_competences for all
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
    using (
        account_id in
        (select id
         from accounts a
         where a.id = entry_account_competences.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    )
    with check (
        account_id in
        (select id
         from accounts a
         where a.id = entry_account_competences.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    );

create policy "everyone in the organisation can read files"
    on storage.objects for select
    using (bucket_id in (select concat('org_', identity_organisation_ids())));

create policy "everyone in the organisation can upload files"
    on storage.objects for insert with check (bucket_id in (select concat('org_', identity_organisation_ids())));

--todo: this is not right.
create policy "owner,admin,teacher can manage entry_files"
    on public.entry_files for all
    using (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    )
    with check (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    );


create policy "owner,admin,teacher can manage events"
    on public.events for all
    using (
        organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );

-- todo: respect teacher roles
create policy "owner,admin,teacher can manage entry_events"
    on public.entry_events for all
    using (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    )
    with check (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    );

create policy "owner,admin,teacher can manage reports"
    on public.reports for all
    using (
        (select a.organisation_id
         from accounts a
         where a.id = account_id) in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        (select a.organisation_id
         from accounts a
         where a.id = account_id) in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );

-- todo: respect teacher roles
create policy "owner,admin,teacher can manage event_competences"
    on public.event_competences for all
    using (
        (select organisation_id
         from events
         where id = event_competences.event_id) in
        (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        (select organisation_id
         from events
         where id = event_competences.event_id) in
        (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );


-- bucket policy
create policy "everyone from the organisation can crud the bucket" on storage.buckets for all
    using (
        trim(leading 'org_' from buckets.name) in (select identity_organisation_ids())
    )
    with check (
        trim(leading 'org_' from buckets.name) in (select identity_organisation_ids())
    );create or replace function entry_accounts_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id text;
    entry_org_id   text;
begin
    -- make sure that account and entry are from the same organisation
    select organisation_id into account_org_id from accounts where id = new.account_id;
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    assert account_org_id = entry_org_id, 'entry and account are not from the same organisation';
    return new;
end
$$;
create trigger entry_accounts_trigger
    before insert or update
    on entry_accounts
    for each row
execute function entry_accounts_trigger();

create or replace function entry_account_competences_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id    text;
    entry_org_id      text;
    competence_org_id text;
begin
    -- make sure that account and entry are from the same organisation
    select organisation_id into account_org_id from accounts where id = new.account_id;
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;
    select c.organisation_id into competence_org_id from competences c where c.id = new.competence_id;

    assert account_org_id = entry_org_id, 'entry, account and competence are not from the same organisation';
    assert account_org_id = competence_org_id, 'entry, account and competence are not from the same organisation';
    return new;
end
$$;
create trigger entry_account_competences_trigger
    before insert or update
    on entry_account_competences
    for each row
execute function entry_account_competences_trigger();

create or replace function entry_files_trigger() returns trigger
    language plpgsql as
$$
declare
    entry_org_id text;
begin
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    assert new.file_bucket_id = concat('org_', entry_org_id), 'entry, file are not from the same organisation';
    return new;
end
$$;
create trigger entry_files_trigger
    before insert or update
    on entry_files
    for each row
execute function entry_files_trigger();

create or replace function entry_events_trigger() returns trigger
    language plpgsql as
$$
declare
    _entry_org_id           text;
    declare _event_org_id text;
begin
    select a.organisation_id
    into _entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;
    select p.organisation_id into _event_org_id from events p where p.id = new.event_id;

    assert _entry_org_id = _event_org_id, 'entry and event are not from the same organisation';
    return new;
end
$$;
create trigger entry_events_trigger
    before insert or update
    on entry_events
    for each row
execute function entry_events_trigger();

create or replace function reports_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id text;
    student_org_id text;
begin
    select organisation_id
    into account_org_id
    from accounts
    where id = new.account_id;

    if new.file_bucket_id is not null then
        assert new.file_bucket_id = concat('org_', account_org_id), 'report, file are not from the same organisation';
    end if;

    select organisation_id
    into student_org_id
    from accounts
    where id = new.student_account_id;

    assert account_org_id = student_org_id, 'account and student are not from the same organisation';

    return new;
end
$$;
create trigger reports_trigger
    before insert or update
    on public.reports
    for each row
execute function reports_trigger();

create or replace function report_files_trigger() returns trigger
    language plpgsql as
$$
BEGIN
    perform pg_notify('app.report_created', NEW.id);
    RETURN new;
END;
$$;
create trigger new_report_trigger
    after insert
    on public.reports
    for each row
execute procedure report_files_trigger();

create or replace function competences_trigger() returns trigger
    language plpgsql as
$$
declare
    competence_parent_org_id text;
begin
    if new.competence_id is null then
        return new;
    end if;

    select organisation_id
    into competence_parent_org_id
    from public.competences
    where id = new.competence_id;

    assert new.organisation_id = competence_parent_org_id, 'competence and competence parent are not from the same organisation';
    return new;
end
$$;

create constraint trigger competences_trigger
    after insert or update
    on public.competences
    deferrable
    for each row
execute function competences_trigger();

create or replace function event_competences_trigger() returns trigger
    language plpgsql as
$$
declare
    event_org_id    text;
    competence_org_id text;
begin
    select organisation_id
    into event_org_id
    from events
    where id = new.event_id;

    select organisation_id
    into competence_org_id
    from competences
    where id = new.competence_id;

    assert competence_org_id = event_org_id, 'event, competence are not from the same organisation';
    return new;
end
$$;
create trigger event_competences_trigger
    before insert or update
    on public.event_competences
    for each row
execute function event_competences_trigger();

create or replace function accounts_trigger() returns trigger
    language plpgsql as
$$
begin
    if new.avatar_file_bucket_id is not null then
        assert new.avatar_file_bucket_id = concat('org_', new.organisation_id), 'account, file are not from the same organisation';
    end if;

    return new;
end
$$;
create trigger accounts_trigger
    before insert or update
    on public.accounts
    for each row
execute function accounts_trigger();

create or replace function deleted_at_trigger() returns trigger
    language plpgsql as
$$
begin
    execute 'UPDATE ' || tg_table_name || ' SET deleted_at = now() where id = ''' || old.id || '''';
    return null;
end
$$;

-- create trigger on all tables that have a deleted_at column
do language plpgsql
$$
    declare
        t      text;
        tables text[] := array ['accounts', 'addresses', 'competences', 'entries', 'entry_account_competences', 'entry_accounts', 'entry_files', 'entry_events', 'identities', 'organisations', 'events', 'event_competences', 'reports'];
    begin
        foreach t in array tables
            loop
                execute 'create trigger deleted_at_trigger before delete on public.' || t ||
                        ' for each row when (coalesce(current_setting(''app.hard_delete'', true), ''off'') <> ''on'') execute function deleted_at_trigger();';
            end loop;
    end
$$;
create or replace function get_competence_tree(_competence_id text) returns table(id text, name text, competence_type text, grades int[], competence_id text, created_at timestamptz) language plpgsql set search_path = 'public' security definer as $$
declare
    _base_competence_org_id text;
    begin

    select organisation_id into _base_competence_org_id from competences where competences.id = _competence_id;
    assert _base_competence_org_id in (select identity_organisation_ids()) or current_setting('request.jwt.claim.role', true) = 'service_role', 'competence not found';

    -- expect that if the user is allowed to see the base competence, they are also allowed to see the parents.
    return query with recursive tree(id, name, competence_type, grades, competence_id, created_at) as (
            select n.id, n.name, n.competence_type, n.grades, n.competence_id, n.created_at
            from competences n
            where n.id = _competence_id
            union all
            select n.id, n.name, n.competence_type, n.grades, n.competence_id, n.created_at
            from competences n
                     join tree t on (n.id = t.competence_id)
        )
        select *
        from tree;
end
    $$;create view view_entries as
(
with org_ids as materialized (select identity_organisation_ids_role('{owner, admin, teacher}'::text[]))
select e.* from entries e
  inner join accounts a on a.id = e.account_id
where a.organisation_id in (select * from org_ids)
);create index on entry_accounts (account_id);
alter table reports
    drop constraint reports_type_check,
    add constraint reports_type_check
        check (type in ('report', 'subjects', 'report_docx'));create index on entry_accounts (account_id);
alter table reports
    drop constraint reports_type_check,
    add constraint reports_type_check
        check (type in ('report', 'subjects', 'report_docx', 'subjects_docx'));alter table accounts
  add column birthday date null;create or replace function export_events(_organisation_id text, _from date, _to date, _show_archived bool)
    returns TABLE
            (
                id        text,
                title     text,
                body      text,
                starts_at timestamptz,
                ends_at   timestamptz,
                subjects  jsonb
            )
    security definer
    set search_path = "public"
    language plpgsql
as
$$
begin
    -- check that the user has rights to export for this organisation
    assert _organisation_id in (select identity_organisation_ids()) or
           current_setting('request.jwt.claim.role', true) = 'service_role', 'organisation not found';

    return query
        -- get all competences which are linked to events. this can happen from two ways.
        -- they are de-duplicated via distinct union & selection.
        with _competences as (
            -- way 1: directly linked via event event_competences>competences
            select distinct on (e.id, c.id) e.id as event_id,
                                            c.id,
                                            c.name,
                                            c.competence_id,
                                            c.grades
            from events e
                     inner join event_competences ec on e.id = ec.event_id
                     inner join competences c on ec.competence_id = c.id
            where e.organisation_id = _organisation_id
              and e.starts_at >= _from
              and e.ends_at <= _to
              and (_show_archived or e.deleted_at is null)
              and c.deleted_at is null
              -- union both ways.
            union
            distinct
            -- way 2: indirect via entry_events>events>eac>competences
            select distinct on (e.id, c.id) e.id, c.id, c.name, c.competence_id, c.grades
            from events e
                     inner join entry_events ee on e.id = ee.event_id
                     inner join entries en on ee.entry_id = en.id
                     inner join entry_account_competences eac on en.id = eac.entry_id
                     inner join competences c on eac.competence_id = c.id
            where e.organisation_id = _organisation_id
              and e.starts_at >= _from
              and e.ends_at <= _to
              and (_show_archived or e.deleted_at is null)
              and en.deleted_at is null
              and eac.deleted_at is null
              and c.deleted_at is null),

             -- next, for each found competence, fetch the whole competence tree
             _competence_trees as (select c.event_id,
                                          c.id,
                                          c.name,
                                          c.competence_id,
                                          c.grades,
                                          jsonb_agg(b) as competence_tree
                                   from _competences c,
                                        -- use lateral subquery (to get all rows from the function)
                                        lateral (select * from get_competence_tree(c.id)) b
                                        -- since the lateral subquery produces multiple rows, we need to group by & use json aggregation
                                   group by c.event_id, c.id, c.name, c.competence_id, c.grades),

             -- for each found competence, fetch the subject (last entry in competence tree).
             -- we then group them by subject, and store the competences using the jsonb_agg
             _subjects as (select ct.event_id,
                                  jsonb_array_element(ct.competence_tree,
                                                      jsonb_array_length(ct.competence_tree) - 1) ->
                                  'id'          as subject_id,
                                  jsonb_array_element(ct.competence_tree,
                                                      jsonb_array_length(ct.competence_tree) - 1) ->
                                  'name'        as subject_name,
                                  jsonb_agg(ct) as competences
                           from _competence_trees ct
                           group by ct.event_id, subject_id, subject_name)
             -- finally, using all of this info, we can run the main query. select all events again, and group by event so
             -- all of their found subjects land in a final jsonb_agg.
        select e.id,
               e.title,
               e.body,
               e.starts_at,
               e.ends_at,
               jsonb_agg(s) FILTER ( WHERE s is not null ) as subjects
        from events e
                 left join _subjects s on e.id = s.event_id
        where e.organisation_id = _organisation_id
          and e.starts_at >= _from
          and e.ends_at <= _to
          and (_show_archived or e.deleted_at is null)
        group by e.id, e.title
        order by e.ends_at;
end;
$$;create table tags
(
    id              text      not null primary key default nanoid(),
    name            text      not null,
    organisation_id text      not null references organisations (id),
    created_by      text      not null references accounts (id),
    created_at      timestamptz not null             default now(),
    deleted_at      timestamptz                      default null,

    unique (name, organisation_id)
);

create table entry_tags
(
    id              text not null primary key default nanoid(),
    entry_id        text not null references entries (id),
    tag_id          text not null references tags (id),
    organisation_id text not null references organisations (id),
    created_at      timestamptz not null             default now(),
    deleted_at      timestamptz                      default null,

    unique (id, entry_id, tag_id)
);

create function tags_cu_trigger() returns trigger
    set search_path = public
    security definer
    language plpgsql as
$$
declare
    created_by_organisation_id text;
begin
    -- make sure that the tag and the account "created_by" are in the same organisation
    select organisation_id into created_by_organisation_id from accounts where id = new.created_by;

    if (new.organisation_id != created_by_organisation_id) then
        raise exception 'Tag and account "created_by" must be in the same organisation';
    end if;

    -- created_by must be one of the accounts from the current user
    if (new.created_by not in (select identity_account_ids())) then
        raise exception 'Tag "created_by" must be one of the accounts from the current user';
    end if;

    return new;
end;
$$;

create trigger tags_cu_trigger
    before insert or update
    on tags
    for each row
execute procedure tags_cu_trigger();

create function entry_tags_cu_trigger() returns trigger
    set search_path = public
    security definer
    language plpgsql as
$$
declare
    entry_organisation_id text;
    tag_organisation_id   text;
begin
    -- make sure that the entry, the tag, and the entry_tag are in the same organisation
    select a.organisation_id
    into entry_organisation_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    select organisation_id into tag_organisation_id from tags where id = new.tag_id;

    if (new.organisation_id != entry_organisation_id or new.organisation_id != tag_organisation_id) then
        raise exception 'Entry, tag and entry_tag must be in the same organisation';
    end if;

    return new;
end;
$$;

create trigger entry_tags_cu_trigger
    before insert or update
    on entry_tags
    for each row
execute procedure entry_tags_cu_trigger();

-- rls
alter table tags enable row level security;
alter table entry_tags enable row level security;

-- teacher, admin, owner are allowed to crud tags for their own organisation
create policy "teacher,admin,owner crud tags"
    on tags
    for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])));

-- whole organisation can read tags
create policy "read tags"
    on tags
    for select
    using (organisation_id in (select identity_organisation_ids()));


-- guest_teacher, teacher, admin, owner are allowed to crud entry_tags for their own organisation
create policy "guest_teacher,teacher,admin,owner crud entry_tags"
    on entry_tags
    for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher,teacher_guest}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher,teacher_guest}'::text[])));

alter table reports
add column filter_tags text[] null default null check ( filter_tags is null or array_length(filter_tags, 1) > 0 );alter table accounts
    add grade integer null default null;create unique index event_competences_unique_event_id_competence_id
    on event_competences (event_id, competence_id);create or replace function is_allowed_to_crud_entry(_entry_account_id text) returns boolean
    security definer
    SET search_path = public
    language plpgsql
as
$$
declare
    _author accounts;
begin
    -- get the organisation of the entry
    select a.* into _author from accounts a where a.id = _entry_account_id limit 1;

    -- check if the user is the author of the entry
    if (_author.id in (select identity_account_ids_role('{owner, admin, teacher}'::text[]))) then
        return true;
    end if;

    -- check if the user is owner, admin or teacher in the organisation
    if (_author.organisation_id in (select identity_organisation_ids_role('{owner, admin, teacher}'::text[]))) then
        return true;
    end if;

    return false;
end;
$$;