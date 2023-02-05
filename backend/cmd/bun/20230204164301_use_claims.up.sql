-- add claim to all auth.users
-- create table `public.users´ and migrate data from `public.accounts` and `public.identities´
-- update all existing rls policies
-- add `domains text[]` to `public.organisations´
/***********/
-- add user_id to public.accounts
ALTER TABLE public.accounts
    ADD COLUMN user_id uuid REFERENCES auth.users (id);

-- update user id in public.accounts, set it to the user_id of the identity
UPDATE
    public.accounts
SET
    user_id = (
        SELECT
            user_id
        FROM
            public.identities
        WHERE
            public.identities.id = public.accounts.identity_id);

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
    SELECT
        id
    FROM
        auth.users LOOP
            SELECT
                id INTO organisation_id
            FROM
                public.account_id
            WHERE
                user_id = r.id;
            -- if
            -- assert only on account per user
            PERFORM
                set_claim (r.id, 'dokedu_organisation_id', '"' || organisation_id || '"');
        END LOOP;
END;
$$;

-- we no longer need the identities table
DROP TABLE public.identities;

-- return all public.identities with the count of public.accounts
SELECT
    public.identities.id,
    public.identities.user_id,
    count(public.accounts.id)
FROM
    public.identities
    LEFT JOIN public.accounts ON public.identities.id = public.accounts.identity_id
GROUP BY
    public.identities.id,
    public.identities.user_id;

