CREATE FUNCTION entry_accounts_trigger ()
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

