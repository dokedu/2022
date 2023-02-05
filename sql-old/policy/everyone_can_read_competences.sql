CREATE POLICY "everyone can read competences" ON competences AS permissive
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids () AS identity_organisation_ids));

