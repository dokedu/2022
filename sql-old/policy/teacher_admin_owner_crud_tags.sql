CREATE POLICY "teacher,admin,owner crud tags" ON tags AS permissive
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role))
                WITH CHECK (organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role));

