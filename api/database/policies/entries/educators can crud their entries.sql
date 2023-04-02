CREATE POLICY "educators can crud their entries" ON entries AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"educator"')
            AND (to_jsonb (account_id) = get_my_claim ('dokedu_account_id'))
            WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"educator"'
            AND to_jsonb (account_id) = get_my_claim ('dokedu_account_id'));

-- TODO:
