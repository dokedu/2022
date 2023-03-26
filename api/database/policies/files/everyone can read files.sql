CREATE POLICY "everyone can read files" ON files AS permissive
    FOR ALL
        USING (TRUE);

