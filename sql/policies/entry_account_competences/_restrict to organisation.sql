CREATE POLICY "restrict to organisation" ON entry_account_competences AS RESTRICTIVE
    FOR ALL
        USING (to_jsonb (organisation_id) = get_my_claim ('dokedu_organisation_id'))
        WITH CHECK (to_jsonb (organisation_id) = get_my_claim ('dokedu_organisation_id'));

