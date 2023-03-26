CREATE POLICY "everyone can update their account" ON accounts AS permissive
    FOR UPDATE
        USING (user_id = auth.uid ())
        WITH CHECK (user_id = auth.uid ());

