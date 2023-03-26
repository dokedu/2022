CREATE POLICY "admins can crud organisation entries" ON organisation_entries AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"admin"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"admin"');

