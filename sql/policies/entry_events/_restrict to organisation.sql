CREATE POLICY "restrict to organisation" ON entry_events AS RESTRICTIVE
    FOR ALL
        USING (to_jsonb (organisation_id) = get_my_claim ('dokedu_organisation_id'))
        WITH CHECK (to_jsonb (organisation_id) = get_my_claim ('dokedu_organisation_id'));

