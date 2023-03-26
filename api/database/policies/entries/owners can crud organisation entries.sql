CREATE POLICY "owners can crud organisation entries" ON entries AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"owner"');

