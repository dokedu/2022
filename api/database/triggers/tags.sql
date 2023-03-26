-- assert tag and tag.created_by (account) are from the same organisation
CREATE TRIGGER tags_cu_trigger
    BEFORE INSERT OR UPDATE ON tags
    FOR EACH ROW
    EXECUTE PROCEDURE tags_cu_trigger ();

CREATE FUNCTION tags_cu_trigger ()
    RETURNS TRIGGER
    SECURITY DEFINER
    SET search_path = public
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

