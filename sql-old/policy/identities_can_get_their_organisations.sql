CREATE POLICY "identities can get their organisations" ON organisations AS permissive
    FOR SELECT
        USING (id IN (
            SELECT
                identity_organisation_ids () AS identity_organisation_ids));

