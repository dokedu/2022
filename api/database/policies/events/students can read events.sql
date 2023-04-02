CREATE POLICY "students can read events" ON events AS permissive
    FOR SELECT
        USING (get_my_claim ('dokedu_organisation_role') = '"student"');

