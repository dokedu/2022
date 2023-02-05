CREATE FUNCTION reports_trigger ()
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

