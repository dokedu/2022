CREATE POLICY "students can read events" ON events AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"student"');

