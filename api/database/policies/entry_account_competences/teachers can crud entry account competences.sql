CREATE POLICY "teachers can crud entry account competences" ON entry_account_competences AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"teacher"');

