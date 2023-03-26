CREATE POLICY "teachers can crud entry tags" ON entry_tags AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"teacher"');
