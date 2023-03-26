CREATE POLICY "everyone can read accounts" ON accounts AS permissive
    FOR SELECT
        USING (TRUE);

