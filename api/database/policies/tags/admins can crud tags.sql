CREATE POLICY "admins can crud tags" ON tags AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"admin"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"admin"');

