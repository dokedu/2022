CREATE FUNCTION identity_organisation_ids ()
    RETURNS SETOF text
    SECURITY DEFINER
    SET search_path = public
    LANGUAGE sql
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

