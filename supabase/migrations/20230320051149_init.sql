-- generated file
CREATE OR REPLACE FUNCTION nanoid (size int DEFAULT 21)
    RETURNS text
    AS $$
DECLARE
    id text := '';
    i int := 0;
    urlAlphabet char(64) := 'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';
    bytes bytea := extensions.gen_random_bytes(size);
    byte int;
    pos int;
BEGIN
    WHILE i < size LOOP
        byte := get_byte(bytes, i);
        pos := (byte & 63) + 1;
        -- + 1 because substr starts at 1 for some reason
        id := id || substr(urlAlphabet, pos, 1);
        i = i + 1;
    END LOOP;
    RETURN id;
END
$$
LANGUAGE PLPGSQL
STABLE;

CREATE TABLE public.identities (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    global_role text NOT NULL CHECK (global_role IN ('superadmin', 'default')),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id uuid NOT NULL UNIQUE,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.identities (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.addresses (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    street text NOT NULL,
    zip text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    country text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.addresses (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.organisations (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    name text NOT NULL,
    address_id text NOT NULL REFERENCES addresses (id),
    legal_name text NOT NULL,
    website text NOT NULL,
    phone text NOT NULL,
    owner_id text NOT NULL REFERENCES identities (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.organisations (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.accounts (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    role text NOT NULL CHECK (ROLE IN ('owner', 'admin', 'teacher', 'teacher_guest', 'student')),
    identity_id text NULL REFERENCES public.identities (id),
    organisation_id text NOT NULL REFERENCES public.organisations (id),
    first_name text NOT NULL,
    last_name text NOT NULL,
    avatar_file_bucket_id text NULL,
    avatar_file_name text NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL,
    joined_at timestamptz NULL DEFAULT NULL,
    left_at timestamptz NULL DEFAULT NULL,
    FOREIGN KEY (avatar_file_bucket_id, avatar_file_name) REFERENCES storage.objects (bucket_id, name)
);

CREATE INDEX ON public.accounts USING HASH (identity_id);

CREATE INDEX ON public.accounts (ROLE);

CREATE INDEX ON public.accounts (deleted_at)
WHERE
    deleted_at IS NULL;

-- auth helper functions
CREATE OR REPLACE FUNCTION identity_id ()
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        id
    FROM
        public.identities
    WHERE
        user_id = auth.uid ()
        AND deleted_at IS NULL
    LIMIT 1;

$$;

CREATE OR REPLACE FUNCTION identity_account_ids ()
    RETURNS SETOF text
    LANGUAGE sql
    SET search_path = public
    SECURITY DEFINER
    AS $$
    WITH _iid AS (
        SELECT
            identity_id ())
    SELECT
        id
    FROM
        public.accounts
    WHERE
        identity_id = (
            SELECT
                *
            FROM
                _iid)
        AND deleted_at IS NULL
$$;

CREATE OR REPLACE FUNCTION identity_account_ids_role (_roles text[])
    RETURNS SETOF text
    LANGUAGE sql
    SET search_path = public
    SECURITY DEFINER
    AS $$
    WITH _iid AS (
        SELECT
            identity_id ())
    SELECT
        id
    FROM
        public.accounts a
    WHERE
        a.identity_id = (
            SELECT
                *
            FROM
                _iid)
        AND a.role = ANY (_roles)
        AND a.deleted_at IS NULL
$$;

CREATE OR REPLACE FUNCTION identity_organisation_ids ()
    RETURNS SETOF text
    LANGUAGE sql
    SET search_path = public
    SECURITY DEFINER
    AS $$
    WITH _iid AS (
        SELECT
            identity_id ())
    SELECT
        organisation_id
    FROM
        public.accounts
    WHERE
        identity_id = (
            SELECT
                *
            FROM
                _iid)
        AND deleted_at IS NULL
$$;

CREATE OR REPLACE FUNCTION identity_organisation_ids_role (_roles text[])
    RETURNS SETOF text
    LANGUAGE sql
    SET search_path = public
    SECURITY DEFINER
    AS $$
    WITH _iid AS (
        SELECT
            identity_id ())
    SELECT
        organisation_id
    FROM
        public.accounts a
    WHERE
        a.identity_id = (
            SELECT
                *
            FROM
                _iid)
        AND a.role = ANY (_roles)
        AND a.deleted_at IS NULL
$$;

CREATE TABLE public.entries (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    date date NOT NULL,
    body jsonb NOT NULL,
    account_id text NOT NULL REFERENCES public.accounts (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.entries (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE INDEX ON public.entries (created_at nulls LAST);

CREATE TABLE public.entry_accounts (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    entry_id text NOT NULL REFERENCES public.entries (id),
    account_id text NOT NULL REFERENCES public.accounts (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.entry_accounts (entry_id, account_id);

CREATE INDEX ON public.entry_accounts (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.competences (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    name text NOT NULL,
    competence_id text NULL,
    competence_type text NOT NULL CHECK (competence_type IN ('subject', 'group', 'competence')),
    organisation_id text NOT NULL,
    grades int[] NOT NULL,
    color text NULL,
    curriculum_id text NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX competences_type ON public.competences USING HASH (competence_type);

CREATE INDEX ON public.competences (competence_id, competence_type);

CREATE INDEX ON public.competences (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.entry_account_competences (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    level int NOT NULL CHECK (level <= 3 AND level >= 0),
    account_id text NOT NULL REFERENCES public.accounts (id),
    entry_id text NOT NULL REFERENCES public.entries (id),
    competence_id text NOT NULL REFERENCES public.competences (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL,
    UNIQUE (account_id, entry_id, competence_id)
);

CREATE INDEX ON public.entry_account_competences (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.entry_files (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    entry_id text NOT NULL REFERENCES public.entries (id),
    file_bucket_id text NOT NULL,
    file_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL,
    FOREIGN KEY (file_bucket_id, file_name) REFERENCES storage.objects (bucket_id, name),
    UNIQUE (entry_id, file_bucket_id, file_name)
);

CREATE INDEX ON public.entry_files (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.events (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    image_file_bucket_id text NULL,
    image_file_name text NULL,
    organisation_id text NOT NULL REFERENCES organisations (id),
    title text NOT NULL,
    body text NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    recurrence text[] NULL DEFAULT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL,
    FOREIGN KEY (image_file_bucket_id, image_file_name) REFERENCES storage.objects (bucket_id, name)
);

CREATE INDEX ON public.events (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.entry_events (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    entry_id text NOT NULL REFERENCES entries (id),
    event_id text NOT NULL REFERENCES events (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.entry_events (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.reports (
    id text NOT NULL DEFAULT nanoid (),
    file_bucket_id text NULL,
    file_name text NULL,
    status text NOT NULL CHECK (status IN ('pending', 'done', 'error')) DEFAULT 'pending',
    type text NOT NULL CHECK (type IN ('report', 'subjects')),
    "from" timestamptz NOT NULL,
    "to" timestamptz NOT NULL,
    account_id text NOT NULL REFERENCES accounts (id),
    student_account_id text NOT NULL REFERENCES accounts (id),
    meta jsonb NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL,
    FOREIGN KEY (file_bucket_id, file_name) REFERENCES storage.objects (bucket_id, name),
    CHECK ((status IN ('pending', 'error') AND file_bucket_id IS NULL AND file_name IS NULL) OR (status IN ('done') AND file_bucket_id IS NOT NULL AND file_name IS NOT NULL))
);

CREATE INDEX ON public.reports (deleted_at)
WHERE
    deleted_at IS NULL;

CREATE TABLE public.event_competences (
    id text PRIMARY KEY DEFAULT nanoid (),
    event_id text NOT NULL REFERENCES events (id),
    competence_id text NOT NULL REFERENCES competences (id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamptz NULL DEFAULT NULL
);

CREATE INDEX ON public.event_competences (deleted_at)
WHERE
    deleted_at IS NULL;

ALTER TABLE public.organisations ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.identities ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entry_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.competences ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entry_account_competences ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entry_files ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entry_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.event_competences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can get their identities" ON public.identities
    FOR SELECT
        USING (user_id = auth.uid ());

CREATE POLICY "identities can get their organisations" ON public.organisations
    FOR SELECT
        USING (id IN (
            SELECT
                identity_organisation_ids ()));

CREATE POLICY "identities can get their accounts" ON public.accounts
    FOR SELECT
        USING (id IN (
            SELECT
                identity_account_ids ()));

CREATE POLICY "owner,admin can crud accounts in their organisations" ON public.accounts
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin}'::text[])))
            WITH CHECK (organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin}'::text[])));

CREATE POLICY "everyone can read accounts in their organisations" ON public.accounts
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids ()));

CREATE OR REPLACE FUNCTION is_allowed_to_crud_entry (_entry_account_id text)
    RETURNS bool
    SECURITY DEFINER
    SET search_path = 'public'
    LANGUAGE plpgsql
    AS $$
DECLARE
    _author accounts;
BEGIN
    -- get the organisation of the entry
    SELECT
        a.* INTO _author
    FROM
        accounts a
    WHERE
        a.id = _entry_account_id
    LIMIT 1;
    -- check if the user is the author of the entry
    IF (_author.id IN (
        SELECT
            identity_account_ids_role ('{owner, admin, teacher}'::text[]))) THEN
        RETURN TRUE;
    END IF;
    -- check if the user is owner or admin in the organisation
    IF (_author.organisation_id IN (
        SELECT
            identity_organisation_ids_role ('{owner, admin}'::text[]))) THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$;

CREATE POLICY "entires_rls" ON public.entries
    FOR ALL
        USING (is_allowed_to_crud_entry (account_id))
        WITH CHECK (is_allowed_to_crud_entry (account_id));

--todo: might be insecure for teacher
CREATE POLICY "owner,admin,teacher can manage entry_accounts" ON public.entry_accounts
    FOR ALL
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
        USING (account_id IN (
            SELECT
                id
            FROM
                accounts a
            WHERE
                a.id = entry_accounts.account_id AND organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))))
                    WITH CHECK (account_id IN (
                        SELECT
                            id
                        FROM
                            accounts a
                        WHERE
                            a.id = entry_accounts.account_id AND organisation_id IN (
                                SELECT
                                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))));

CREATE POLICY "everyone can read competences" ON public.competences
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids ()));

CREATE POLICY "owner,admin can crud competences" ON public.competences
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin}'::text[])))
            WITH CHECK (organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin}'::text[])));

-- todo insecure for teacher
CREATE POLICY "owner,admin,teacher can manage entry_account_competences" ON public.entry_account_competences
    FOR ALL
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
        USING (account_id IN (
            SELECT
                id
            FROM
                accounts a
            WHERE
                a.id = entry_account_competences.account_id AND organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))))
                    WITH CHECK (account_id IN (
                        SELECT
                            id
                        FROM
                            accounts a
                        WHERE
                            a.id = entry_account_competences.account_id AND organisation_id IN (
                                SELECT
                                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))));

CREATE POLICY "everyone in the organisation can read files" ON storage.objects
    FOR SELECT
        USING (bucket_id IN (
            SELECT
                concat('org_', identity_organisation_ids ())));

CREATE POLICY "everyone in the organisation can upload files" ON storage.objects
    FOR INSERT
        WITH CHECK (bucket_id IN (
            SELECT
                concat('org_', identity_organisation_ids ())));

--todo: this is not right.
CREATE POLICY "owner,admin,teacher can manage entry_files" ON public.entry_files
    FOR ALL
        USING (EXISTS ((
            SELECT
                entries.id
            FROM
                entries
                INNER JOIN accounts a ON a.id = account_id AND a.organisation_id IN (
                        SELECT
                            identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))
                    WHERE
                        entries.id = entry_id)))
                    WITH CHECK (EXISTS ((
                        SELECT
                            entries.id
                        FROM
                            entries
                            INNER JOIN accounts a ON a.id = account_id AND a.organisation_id IN (
                                    SELECT
                                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))
                                WHERE
                                    entries.id = entry_id)));

CREATE POLICY "owner,admin,teacher can manage events" ON public.events
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin,teacher}'::text[])))
            WITH CHECK (organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[])));

-- todo: respect teacher roles
CREATE POLICY "owner,admin,teacher can manage entry_events" ON public.entry_events
    FOR ALL
        USING (EXISTS ((
            SELECT
                entries.id
            FROM
                entries
                INNER JOIN accounts a ON a.id = account_id AND a.organisation_id IN (
                        SELECT
                            identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))
                    WHERE
                        entries.id = entry_id)))
                    WITH CHECK (EXISTS ((
                        SELECT
                            entries.id
                        FROM
                            entries
                            INNER JOIN accounts a ON a.id = account_id AND a.organisation_id IN (
                                    SELECT
                                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]))
                                WHERE
                                    entries.id = entry_id)));

CREATE POLICY "owner,admin,teacher can manage reports" ON public.reports
    FOR ALL
        USING ((
            SELECT
                a.organisation_id
            FROM
                accounts a
            WHERE
                a.id = account_id) IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[])))
                    WITH CHECK ((
                        SELECT
                            a.organisation_id
                        FROM
                            accounts a
                        WHERE
                            a.id = account_id) IN (
                                SELECT
                                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[])));

-- todo: respect teacher roles
CREATE POLICY "owner,admin,teacher can manage event_competences" ON public.event_competences
    FOR ALL
        USING ((
            SELECT
                organisation_id
            FROM
                events
            WHERE
                id = event_competences.event_id) IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[])))
                    WITH CHECK ((
                        SELECT
                            organisation_id
                        FROM
                            events
                        WHERE
                            id = event_competences.event_id) IN (
                                SELECT
                                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[])));

-- bucket policy
CREATE POLICY "everyone from the organisation can crud the bucket" ON storage.buckets
    FOR ALL
        USING (trim(LEADING 'org_' FROM buckets.name) IN (
            SELECT
                identity_organisation_ids ()))
            WITH CHECK (trim(LEADING 'org_' FROM buckets.name) IN (
                SELECT
                    identity_organisation_ids ()));

CREATE OR REPLACE FUNCTION entry_accounts_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    account_org_id text;
    entry_org_id text;
BEGIN
    -- make sure that account and entry are from the same organisation
    SELECT
        organisation_id INTO account_org_id
    FROM
        accounts
    WHERE
        id = NEW.account_id;
    SELECT
        a.organisation_id INTO entry_org_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    assert account_org_id = entry_org_id,
    'entry and account are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER entry_accounts_trigger
    BEFORE INSERT OR UPDATE ON entry_accounts
    FOR EACH ROW
    EXECUTE FUNCTION entry_accounts_trigger ();

CREATE OR REPLACE FUNCTION entry_account_competences_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    account_org_id text;
    entry_org_id text;
    competence_org_id text;
BEGIN
    -- make sure that account and entry are from the same organisation
    SELECT
        organisation_id INTO account_org_id
    FROM
        accounts
    WHERE
        id = NEW.account_id;
    SELECT
        a.organisation_id INTO entry_org_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    SELECT
        c.organisation_id INTO competence_org_id
    FROM
        competences c
    WHERE
        c.id = NEW.competence_id;
    assert account_org_id = entry_org_id,
    'entry, account and competence are not from the same organisation';
    assert account_org_id = competence_org_id,
    'entry, account and competence are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER entry_account_competences_trigger
    BEFORE INSERT OR UPDATE ON entry_account_competences
    FOR EACH ROW
    EXECUTE FUNCTION entry_account_competences_trigger ();

CREATE OR REPLACE FUNCTION entry_files_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    entry_org_id text;
BEGIN
    SELECT
        a.organisation_id INTO entry_org_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    assert NEW.file_bucket_id = concat('org_', entry_org_id),
    'entry, file are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER entry_files_trigger
    BEFORE INSERT OR UPDATE ON entry_files
    FOR EACH ROW
    EXECUTE FUNCTION entry_files_trigger ();

CREATE OR REPLACE FUNCTION entry_events_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    _entry_org_id text;
    DECLARE _event_org_id text;
BEGIN
    SELECT
        a.organisation_id INTO _entry_org_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    SELECT
        p.organisation_id INTO _event_org_id
    FROM
        events p
    WHERE
        p.id = NEW.event_id;
    assert _entry_org_id = _event_org_id,
    'entry and event are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER entry_events_trigger
    BEFORE INSERT OR UPDATE ON entry_events
    FOR EACH ROW
    EXECUTE FUNCTION entry_events_trigger ();

CREATE OR REPLACE FUNCTION reports_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    account_org_id text;
    student_org_id text;
BEGIN
    SELECT
        organisation_id INTO account_org_id
    FROM
        accounts
    WHERE
        id = NEW.account_id;
    IF NEW.file_bucket_id IS NOT NULL THEN
        assert NEW.file_bucket_id = concat('org_', account_org_id),
        'report, file are not from the same organisation';
    END IF;
    SELECT
        organisation_id INTO student_org_id
    FROM
        accounts
    WHERE
        id = NEW.student_account_id;
    assert account_org_id = student_org_id,
    'account and student are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER reports_trigger
    BEFORE INSERT OR UPDATE ON public.reports
    FOR EACH ROW
    EXECUTE FUNCTION reports_trigger ();

CREATE OR REPLACE FUNCTION report_files_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM
        pg_notify('app.report_created', NEW.id);
    RETURN new;
END;
$$;

CREATE TRIGGER new_report_trigger
    AFTER INSERT ON public.reports
    FOR EACH ROW
    EXECUTE PROCEDURE report_files_trigger ();

CREATE OR REPLACE FUNCTION competences_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    competence_parent_org_id text;
BEGIN
    IF NEW.competence_id IS NULL THEN
        RETURN new;
    END IF;
    SELECT
        organisation_id INTO competence_parent_org_id
    FROM
        public.competences
    WHERE
        id = NEW.competence_id;
    assert NEW.organisation_id = competence_parent_org_id,
    'competence and competence parent are not from the same organisation';
    RETURN new;
END
$$;

CREATE CONSTRAINT TRIGGER competences_trigger
    AFTER INSERT OR UPDATE ON public.competences DEFERRABLE
    FOR EACH ROW
    EXECUTE FUNCTION competences_trigger ();

CREATE OR REPLACE FUNCTION event_competences_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    event_org_id text;
    competence_org_id text;
BEGIN
    SELECT
        organisation_id INTO event_org_id
    FROM
        events
    WHERE
        id = NEW.event_id;
    SELECT
        organisation_id INTO competence_org_id
    FROM
        competences
    WHERE
        id = NEW.competence_id;
    assert competence_org_id = event_org_id,
    'event, competence are not from the same organisation';
    RETURN new;
END
$$;

CREATE TRIGGER event_competences_trigger
    BEFORE INSERT OR UPDATE ON public.event_competences
    FOR EACH ROW
    EXECUTE FUNCTION event_competences_trigger ();

CREATE OR REPLACE FUNCTION accounts_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.avatar_file_bucket_id IS NOT NULL THEN
        assert NEW.avatar_file_bucket_id = concat('org_', NEW.organisation_id),
        'account, file are not from the same organisation';
    END IF;
    RETURN new;
END
$$;

CREATE TRIGGER accounts_trigger
    BEFORE INSERT OR UPDATE ON public.accounts
    FOR EACH ROW
    EXECUTE FUNCTION accounts_trigger ();

CREATE OR REPLACE FUNCTION deleted_at_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE 'UPDATE ' || tg_table_name || ' SET deleted_at = now() where id = ''' || OLD.id || '''';
    RETURN NULL;
END
$$;

-- create trigger on all tables that have a deleted_at column
DO
LANGUAGE plpgsql
$$ DECLARE t text;

tables text[] := ARRAY['accounts', 'addresses', 'competences', 'entries', 'entry_account_competences', 'entry_accounts', 'entry_files', 'entry_events', 'identities', 'organisations', 'events', 'event_competences', 'reports'];

BEGIN
    foreach t IN ARRAY tables LOOP
        EXECUTE 'create trigger deleted_at_trigger before delete on public.' || t || ' for each row when (coalesce(current_setting(''app.hard_delete'', true), ''off'') <> ''on'') execute function deleted_at_trigger();';

END LOOP;

END $$;

CREATE OR REPLACE FUNCTION get_competence_tree (_competence_id text)
    RETURNS TABLE (
        id text,
        name text,
        competence_type text,
        grades int[],
        competence_id text,
        created_at timestamptz)
    LANGUAGE plpgsql
    SET search_path = 'public'
    SECURITY DEFINER
    AS $$
DECLARE
    _base_competence_org_id text;
BEGIN
    SELECT
        organisation_id INTO _base_competence_org_id
    FROM
        competences
    WHERE
        competences.id = _competence_id;
    assert _base_competence_org_id IN (
        SELECT
            identity_organisation_ids ())
        OR current_setting('request.jwt.claim.role', TRUE) = 'service_role',
        'competence not found';
    -- expect that if the user is allowed to see the base competence, they are also allowed to see the parents.
    RETURN query WITH RECURSIVE tree (
        id,
        name,
        competence_type,
        grades,
        competence_id,
        created_at
) AS (
        SELECT
            n.id,
            n.name,
            n.competence_type,
            n.grades,
            n.competence_id,
            n.created_at
        FROM
            competences n
        WHERE
            n.id = _competence_id
        UNION ALL
        SELECT
            n.id,
            n.name,
            n.competence_type,
            n.grades,
            n.competence_id,
            n.created_at
        FROM
            competences n
            JOIN tree t ON (n.id = t.competence_id))
    SELECT
        *
    FROM
        tree;
END
$$;

CREATE VIEW view_entries AS (
    WITH org_ids AS MATERIALIZED (
        SELECT
            identity_organisation_ids_role (
                '{owner, admin, teacher}'::text[]
))
        SELECT
            e.*
        FROM
            entries e
            INNER JOIN accounts a ON a.id = e.account_id
        WHERE
            a.organisation_id IN (
                SELECT
                    *
                FROM
                    org_ids));

CREATE INDEX ON entry_accounts (account_id);

ALTER TABLE reports
    DROP CONSTRAINT reports_type_check,
    ADD CONSTRAINT reports_type_check CHECK (type IN ('report', 'subjects', 'report_docx'));

CREATE INDEX ON entry_accounts (account_id);

ALTER TABLE reports
    DROP CONSTRAINT reports_type_check,
    ADD CONSTRAINT reports_type_check CHECK (type IN ('report', 'subjects', 'report_docx', 'subjects_docx'));

ALTER TABLE accounts
    ADD COLUMN birthday date NULL;

CREATE OR REPLACE FUNCTION export_events (_organisation_id text, _from date, _to date, _show_archived bool)
    RETURNS TABLE (
        id text,
        title text,
        body text,
        starts_at timestamptz,
        ends_at timestamptz,
        subjects jsonb)
    SECURITY DEFINER
    SET search_path = "public"
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- check that the user has rights to export for this organisation
    assert _organisation_id IN (
        SELECT
            identity_organisation_ids ())
        OR current_setting('request.jwt.claim.role', TRUE) = 'service_role',
        'organisation not found';
    RETURN query
    -- get all competences which are linked to events. this can happen from two ways.
    -- they are de-duplicated via distinct union & selection.
    WITH _competences AS (
        -- way 1: directly linked via event event_competences>competences
        SELECT DISTINCT ON (e.id,
            c.id)
            e.id AS event_id,
            c.id,
            c.name,
            c.competence_id,
            c.grades
        FROM
            events e
            INNER JOIN event_competences ec ON e.id = ec.event_id
            INNER JOIN competences c ON ec.competence_id = c.id
        WHERE
            e.organisation_id = _organisation_id
            AND e.starts_at >= _from
            AND e.ends_at <= _to
            AND (_show_archived
                OR e.deleted_at IS NULL)
            AND c.deleted_at IS NULL
            -- union both ways.
        UNION
        DISTINCT
        -- way 2: indirect via entry_events>events>eac>competences
        SELECT DISTINCT ON (e.id,
            c.id)
            e.id,
            c.id,
            c.name,
            c.competence_id,
            c.grades
        FROM
            events e
            INNER JOIN entry_events ee ON e.id = ee.event_id
            INNER JOIN entries en ON ee.entry_id = en.id
            INNER JOIN entry_account_competences eac ON en.id = eac.entry_id
            INNER JOIN competences c ON eac.competence_id = c.id
        WHERE
            e.organisation_id = _organisation_id
            AND e.starts_at >= _from
            AND e.ends_at <= _to
            AND (_show_archived
                OR e.deleted_at IS NULL)
            AND en.deleted_at IS NULL
            AND eac.deleted_at IS NULL
            AND c.deleted_at IS NULL
),
-- next, for each found competence, fetch the whole competence tree
_competence_trees AS (
    SELECT
        c.event_id,
        c.id,
        c.name,
        c.competence_id,
        c.grades,
        jsonb_agg(b) AS competence_tree
    FROM
        _competences c,
        -- use lateral subquery (to get all rows from the function)
        LATERAL (
            SELECT
                *
            FROM
                get_competence_tree (c.id)) b
            -- since the lateral subquery produces multiple rows, we need to group by & use json aggregation
        GROUP BY
            c.event_id,
            c.id,
            c.name,
            c.competence_id,
            c.grades
),
-- for each found competence, fetch the subject (last entry in competence tree).
-- we then group them by subject, and store the competences using the jsonb_agg
_subjects AS (
    SELECT
        ct.event_id,
        jsonb_array_element (ct.competence_tree, jsonb_array_length(ct.competence_tree) - 1) -> 'id' AS subject_id,
        jsonb_array_element (ct.competence_tree, jsonb_array_length(ct.competence_tree) - 1) -> 'name' AS subject_name,
        jsonb_agg(ct) AS competences
FROM
    _competence_trees ct
GROUP BY
    ct.event_id,
    subject_id,
    subject_name)
-- finally, using all of this info, we can run the main query. select all events again, and group by event so
-- all of their found subjects land in a final jsonb_agg.
SELECT
    e.id,
    e.title,
    e.body,
    e.starts_at,
    e.ends_at,
    jsonb_agg(s) FILTER (WHERE s IS NOT NULL) AS subjects
FROM
    events e
    LEFT JOIN _subjects s ON e.id = s.event_id
WHERE
    e.organisation_id = _organisation_id
    AND e.starts_at >= _from
    AND e.ends_at <= _to
    AND (_show_archived
        OR e.deleted_at IS NULL)
GROUP BY
    e.id,
    e.title
ORDER BY
    e.ends_at;
END;
$$;

CREATE TABLE tags (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    name text NOT NULL,
    organisation_id text NOT NULL REFERENCES organisations (id),
    created_by text NOT NULL REFERENCES accounts (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz DEFAULT NULL,
    UNIQUE (name, organisation_id)
);

CREATE TABLE entry_tags (
    id text NOT NULL PRIMARY KEY DEFAULT nanoid (),
    entry_id text NOT NULL REFERENCES entries (id),
    tag_id text NOT NULL REFERENCES tags (id),
    organisation_id text NOT NULL REFERENCES organisations (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz DEFAULT NULL,
    UNIQUE (id, entry_id, tag_id)
);

CREATE FUNCTION tags_cu_trigger ()
    RETURNS TRIGGER
    SET search_path = public
    SECURITY DEFINER
    LANGUAGE plpgsql
    AS $$
DECLARE
    created_by_organisation_id text;
BEGIN
    -- make sure that the tag and the account "created_by" are in the same organisation
    SELECT
        organisation_id INTO created_by_organisation_id
    FROM
        accounts
    WHERE
        id = NEW.created_by;
    IF (NEW.organisation_id != created_by_organisation_id) THEN
        RAISE EXCEPTION 'Tag and account "created_by" must be in the same organisation';
    END IF;
    -- created_by must be one of the accounts from the current user
    IF (NEW.created_by NOT IN (
        SELECT
            identity_account_ids ())) THEN
        RAISE EXCEPTION 'Tag "created_by" must be one of the accounts from the current user';
    END IF;
    RETURN new;
END;
$$;

CREATE TRIGGER tags_cu_trigger
    BEFORE INSERT OR UPDATE ON tags
    FOR EACH ROW
    EXECUTE PROCEDURE tags_cu_trigger ();

CREATE FUNCTION entry_tags_cu_trigger ()
    RETURNS TRIGGER
    SET search_path = public
    SECURITY DEFINER
    LANGUAGE plpgsql
    AS $$
DECLARE
    entry_organisation_id text;
    tag_organisation_id text;
BEGIN
    -- make sure that the entry, the tag, and the entry_tag are in the same organisation
    SELECT
        a.organisation_id INTO entry_organisation_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    SELECT
        organisation_id INTO tag_organisation_id
    FROM
        tags
    WHERE
        id = NEW.tag_id;
    IF (NEW.organisation_id != entry_organisation_id OR NEW.organisation_id != tag_organisation_id) THEN
        RAISE EXCEPTION 'Entry, tag and entry_tag must be in the same organisation';
    END IF;
    RETURN new;
END;
$$;

CREATE TRIGGER entry_tags_cu_trigger
    BEFORE INSERT OR UPDATE ON entry_tags
    FOR EACH ROW
    EXECUTE PROCEDURE entry_tags_cu_trigger ();

-- rls
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

ALTER TABLE entry_tags ENABLE ROW LEVEL SECURITY;

-- teacher, admin, owner are allowed to crud tags for their own organisation
CREATE POLICY "teacher,admin,owner crud tags" ON tags
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin,teacher}'::text[])))
            WITH CHECK (organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[])));

-- whole organisation can read tags
CREATE POLICY "read tags" ON tags
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids ()));

-- guest_teacher, teacher, admin, owner are allowed to crud entry_tags for their own organisation
CREATE POLICY "guest_teacher,teacher,admin,owner crud entry_tags" ON entry_tags
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin,teacher,teacher_guest}'::text[])))
            WITH CHECK (organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher,teacher_guest}'::text[])));

ALTER TABLE reports
    ADD COLUMN filter_tags text[] NULL DEFAULT NULL CHECK (filter_tags IS NULL
        OR array_length(filter_tags, 1) > 0);

ALTER TABLE accounts
    ADD grade integer NULL DEFAULT NULL;

CREATE UNIQUE INDEX event_competences_unique_event_id_competence_id ON event_competences (event_id, competence_id);

CREATE OR REPLACE FUNCTION is_allowed_to_crud_entry (_entry_account_id text)
    RETURNS boolean
    SECURITY DEFINER
    SET search_path = public
    LANGUAGE plpgsql
    AS $$
DECLARE
    _author accounts;
BEGIN
    -- get the organisation of the entry
    SELECT
        a.* INTO _author
    FROM
        accounts a
    WHERE
        a.id = _entry_account_id
    LIMIT 1;
    -- check if the user is the author of the entry
    IF (_author.id IN (
        SELECT
            identity_account_ids_role ('{owner, admin, teacher}'::text[]))) THEN
        RETURN TRUE;
    END IF;
    -- check if the user is owner, admin or teacher in the organisation
    IF (_author.organisation_id IN (
        SELECT
            identity_organisation_ids_role ('{owner, admin, teacher}'::text[]))) THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$;

-- find all identities that have more than 1 account
WITH identities_with_multiple_accounts AS (
    SELECT
        identity_id
    FROM
        accounts
    GROUP BY
        identity_id
    HAVING
        COUNT(*) > 1
)
SELECT
    i.id
FROM
    identities i
WHERE
    i.id IN (
        SELECT
            *
        FROM
            identities_with_multiple_accounts);

-- find all accounts with an identity that has more than 1 account
WITH identities_with_multiple_accounts AS (
    SELECT
        identity_id
    FROM
        accounts
    GROUP BY
        identity_id
    HAVING
        COUNT(*) > 1
)
SELECT
    *
FROM
    accounts
WHERE
    identity_id IN (
        SELECT
            *
        FROM
            identities_with_multiple_accounts);

-- for each identity except id='2UPUiv5T4t' select set_claim (uid uuid, claim text, value jsonb) with claim = 'dokedu_organisation_id' and value = 'organisation_id' of the first account
DO
$$
DECLARE
    _identity_id text;
    _organisation_id text;
BEGIN
    FOR _identity_id IN (
        SELECT
            id
        FROM
            identities
        WHERE
            id != '2UPUiv5T4t'
    ) LOOP
        SELECT
            organisation_id INTO _organisation_id
        FROM
            accounts
        WHERE
            identity_id = _identity_id
        LIMIT 1;
        PERFORM
            set_claim (_identity_id, 'dokedu_organisation_id', _organisation_id::jsonb);
    END LOOP;
END;


