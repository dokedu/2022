CREATE POLICY "read tags" ON tags AS permissive
    FOR SELECT
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids () AS identity_organisation_ids));

