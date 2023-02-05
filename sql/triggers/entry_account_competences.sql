-- assert account, entry and competence are from the same organisation
CREATE TRIGGER entry_account_competences_trigger
    BEFORE INSERT OR UPDATE ON entry_account_competences
    FOR EACH ROW
    EXECUTE PROCEDURE entry_account_competences_trigger ();

CREATE FUNCTION entry_account_competences_trigger ()
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

