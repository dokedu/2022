CREATE POLICY "students can crud their entries" ON entries AS permissive
    FOR ALL
        USING (to_jsonb (account_id) = get_my_claim ('dokedu_account_id')
            AND get_my_claim ('dokedu_organisation_role') = '"student"')
            WITH CHECK (to_jsonb (account_id) = get_my_claim ('dokedu_account_id')
            AND get_my_claim ('dokedu_organisation_role') = '"student"');

