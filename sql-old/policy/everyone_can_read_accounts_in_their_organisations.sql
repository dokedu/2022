CREATE POLICY "everyone can read accounts in their organisations" ON accounts AS permissive
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids () AS identity_organisation_ids));

