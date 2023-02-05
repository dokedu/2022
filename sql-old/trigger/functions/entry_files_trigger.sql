CREATE FUNCTION entry_files_trigger ()
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

