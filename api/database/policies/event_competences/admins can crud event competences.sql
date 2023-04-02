CREATE POLICY "admins can crud event competences" ON event_competences AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"admin"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"admin"');

