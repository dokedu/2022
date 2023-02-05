CREATE POLICY "users can get their identities" ON identities AS permissive
    FOR SELECT
        USING (user_id = auth.uid ());

