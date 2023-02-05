CREATE POLICY "owner,admin,teacher can manage entry_account_competences" ON entry_account_competences AS permissive
    FOR ALL
        USING (account_id IN (
            SELECT
                a.id
            FROM
                accounts a
            WHERE ((a.id = entry_account_competences.account_id) AND (a.organisation_id IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role)))))
                --
                    WITH CHECK (account_id IN (
                        SELECT
                            a.id
                        FROM
                            accounts a
                        WHERE ((a.id = entry_account_competences.account_id) AND (a.organisation_id IN (
                            SELECT
                                identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role)))));

