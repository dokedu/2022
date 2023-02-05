CREATE FUNCTION identity_account_ids ()
    RETURNS SETOF text
    SECURITY DEFINER
    SET search_path = public
    LANGUAGE sql
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

