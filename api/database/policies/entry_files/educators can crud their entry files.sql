CREATE POLICY "educators can crud their entry files" ON entry_files AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"educator"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"educator"');

