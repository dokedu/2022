CREATE POLICY "teachers can crud tags" ON tags AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"teacher"');

