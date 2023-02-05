CREATE FUNCTION is_allowed_to_crud_entry (_entry_account_id text)
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

