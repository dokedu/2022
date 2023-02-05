CREATE FUNCTION identity_account_ids_role (_roles text[])
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

