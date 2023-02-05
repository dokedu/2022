CREATE POLICY "teachers can crud organisation entries" ON entries AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"teacher"');

