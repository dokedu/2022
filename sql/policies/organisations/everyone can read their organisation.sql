CREATE POLICY "everyone can read their organisation" ON organisations AS permissive
    FOR ALL
        USING (TRUE)
