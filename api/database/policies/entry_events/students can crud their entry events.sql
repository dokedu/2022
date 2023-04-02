CREATE POLICY "students can crud their entry events" ON entry_events AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"student"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"student"');

-- TODO: their
