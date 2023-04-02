-- this script can be used to merge two students, if they have been duplicated on accident.
-- it requires, that both accounts are from the same organisation, that from is marked as deleted.
-- it will update reports, entry_accounts and entry_account_competences and replace from with to.
-- afterwards, it hard-deletes the from student.
CREATE OR REPLACE FUNCTION pg_temp.merge_students (from_account_id text, to_account_id text)
    RETURNS void
    LANGUAGE plpgsql
    SET search_path = 'public'
    AS $$
DECLARE
    from_account accounts;
    to_account accounts;
    from_account_ea int;
    to_account_ea int;
    from_account_eac int;
    to_account_eac int;
    from_reports int;
    to_reports int;
BEGIN
    SELECT
        * INTO from_account
    FROM
        accounts
    WHERE
        id = from_account_id;
    --
    SELECT
        * INTO to_account
    FROM
        accounts
    WHERE
        id = to_account_id;
    IF from_account IS NULL OR to_account IS NULL THEN
        RAISE EXCEPTION 'could not find students';
    END IF;
    IF from_account.deleted_at IS NULL THEN
        RAISE EXCEPTION 'from_account must be deleted';
    END IF;
    IF to_account.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'to_account must not be deleted';
    END IF;
    IF from_account.organisation_id != to_account.organisation_id THEN
        RAISE EXCEPTION 'cannot migrate across two organisations';
    END IF;
    IF from_account.first_name != to_account.first_name OR from_account.last_name != to_account.last_name THEN
        RAISE EXCEPTION 'first_name and last_name must be the same';
    END IF;
    IF from_account.role != 'student' OR to_account.role != 'student' THEN
        RAISE EXCEPTION 'can only migrate students';
    END IF;
    -- start by printing info about both students.
    RAISE NOTICE 'migrating student %s to %s', from_account.id, to_account.id;
    SELECT
        count(*) INTO from_account_ea
    FROM
        entry_accounts
    WHERE
        account_id = from_account.id;
    SELECT
        count(*) INTO to_account_ea
    FROM
        entry_accounts
    WHERE
        account_id = to_account.id;
    SELECT
        count(*) INTO from_account_eac
    FROM
        entry_account_competences
    WHERE
        account_id = from_account.id;
    SELECT
        count(*) INTO to_account_eac
    FROM
        entry_account_competences
    WHERE
        account_id = to_account.id;
    SELECT
        count(*) INTO from_reports
    FROM
        reports
    WHERE
        reports.student_account_id = from_account.id;
    SELECT
        count(*) INTO to_reports
    FROM
        reports
    WHERE
        reports.student_account_id = to_account.id;
    RAISE NOTICE 'from student has %, %, %', from_account_ea, from_account_eac, from_reports;
    RAISE NOTICE 'to   student has %, %, %', to_account_ea, to_account_eac, to_reports;
    -- do the actual migration for the student
    -- if there are any duplicates between them two, delete the old ones.
    SET local app.hard_delete = 'on';
    -- idea: duplicates are entry_account_competences among the two accounts where entry_id and competence_id are the same
    WITH duplicates AS (
        SELECT
            entry_id,
            competence_id
        FROM
            entry_account_competences
        WHERE
            account_id = from_account.id
            OR account_id = to_account.id
        GROUP BY
            (entry_id,
                competence_id)
        HAVING
            count(*) > 1
),
-- for those pairs of duplicates, find the id of the eac where account = from
to_delete AS (
    SELECT
        id
    FROM
        entry_account_competences ea
        INNER JOIN duplicates d ON ea.entry_id = d.entry_id
            AND ea.competence_id = d.competence_id
            AND ea.account_id = from_account.id)
        -- and delete those
        DELETE FROM entry_account_competences
    WHERE id IN (
            SELECT
                *
            FROM
                to_delete)
        AND account_id = from_account.id;
    -- duplicates are where entry_id is the same. find those
    WITH duplicate AS (
        SELECT
            entry_id
        FROM
            entry_accounts
        WHERE
            account_id = from_account.id
            OR account_id = to_account.id
        GROUP BY
            (entry_id)
        HAVING
            count(*) > 1)
        -- delete those entries for the from_account.
        DELETE FROM entry_accounts
        WHERE account_id = from_account.id
            AND entry_id IN (
                SELECT
                    *
                FROM
                    duplicate);
    SET local app.hard_delete = 'off';
    -- migrate data
    UPDATE
        entry_accounts
    SET
        account_id = to_account.id
    WHERE
        account_id = from_account.id;
    UPDATE
        entry_account_competences
    SET
        account_id = to_account.id
    WHERE
        account_id = from_account.id;
    UPDATE
        reports
    SET
        student_account_id = to_account.id
    WHERE
        student_account_id = from_account.id;
    -- print logs again
    SELECT
        count(*) INTO from_account_ea
    FROM
        entry_accounts
    WHERE
        account_id = from_account.id;
    SELECT
        count(*) INTO to_account_ea
    FROM
        entry_accounts
    WHERE
        account_id = to_account.id;
    SELECT
        count(*) INTO from_account_eac
    FROM
        entry_account_competences
    WHERE
        account_id = from_account.id;
    SELECT
        count(*) INTO to_account_eac
    FROM
        entry_account_competences
    WHERE
        account_id = to_account.id;
    SELECT
        count(*) INTO from_reports
    FROM
        reports
    WHERE
        reports.student_account_id = from_account.id;
    SELECT
        count(*) INTO to_reports
    FROM
        reports
    WHERE
        reports.student_account_id = to_account.id;
    RAISE NOTICE 'from student has %, %, %', from_account_ea, from_account_eac, from_reports;
    RAISE NOTICE 'to   student has %, %, %', to_account_ea, to_account_eac, to_reports;
    -- delete old account
    SET local app.hard_delete = 'on';
    DELETE FROM accounts
    WHERE id = from_account.id;
    SET local app.hard_delete = 'off';
END;
$$;

