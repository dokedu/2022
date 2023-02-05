CREATE POLICY "owner,admin,teacher can manage entry_events" ON entry_events AS permissive
    FOR ALL
        USING (EXISTS (
            SELECT
                entries.id
            FROM (entries
            JOIN accounts a ON (((a.id = entries.account_id) AND (a.organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role)))))
                WHERE (entries.id = entry_events.entry_id)))
                WITH CHECK (EXISTS (
                    SELECT
                        entries.id
                    FROM (entries
                    JOIN accounts a ON (((a.id = entries.account_id) AND (a.organisation_id IN (
                            SELECT
                                identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role)))))
                        WHERE (entries.id = entry_events.entry_id)));

