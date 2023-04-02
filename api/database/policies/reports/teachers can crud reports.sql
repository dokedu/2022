CREATE POLICY "teachers can crud reports" ON reports AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"teacher"');

