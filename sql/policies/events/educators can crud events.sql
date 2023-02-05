CREATE POLICY "educators can crud events" ON events AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"educator"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"educator"');

