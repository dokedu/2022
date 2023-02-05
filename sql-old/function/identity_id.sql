CREATE FUNCTION identity_id ()
    RETURNS text
    LANGUAGE sql
    AS $$
    SELECT
        id
    FROM
        public.identities
    WHERE
        user_id = auth.uid ()
        AND deleted_at IS NULL
    LIMIT 1;

$$;

