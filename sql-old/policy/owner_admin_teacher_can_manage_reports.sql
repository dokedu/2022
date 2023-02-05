CREATE POLICY "owner,admin,teacher can manage reports" ON reports AS permissive
    FOR ALL
        USING ((
            SELECT
                a.organisation_id
            FROM
                accounts a
            WHERE (a.id = reports.account_id)) IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role))
                    WITH CHECK ((
                        SELECT
                            a.organisation_id
                        FROM
                            accounts a
                        WHERE (a.id = reports.account_id)) IN (
                            SELECT
                                identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role));

