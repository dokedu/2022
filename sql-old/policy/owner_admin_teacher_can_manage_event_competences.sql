CREATE POLICY "owner,admin,teacher can manage event_competences" ON event_competences AS permissive
    FOR ALL
        USING ((
            SELECT
                events.organisation_id
            FROM
                events
            WHERE (events.id = event_competences.event_id)) IN (
                SELECT
                    identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role))
                    WITH CHECK ((
                        SELECT
                            events.organisation_id
                        FROM
                            events
                        WHERE (events.id = event_competences.event_id)) IN (
                            SELECT
                                identity_organisation_ids_role ('{owner,admin,teacher}'::text[]) AS identity_organisation_ids_role));

