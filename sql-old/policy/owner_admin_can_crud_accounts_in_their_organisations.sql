CREATE POLICY "owner,admin can crud accounts in their organisations" ON accounts AS permissive
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin}'::text[]) AS identity_organisation_ids_role))
                WITH CHECK (organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin}'::text[]) AS identity_organisation_ids_role));

