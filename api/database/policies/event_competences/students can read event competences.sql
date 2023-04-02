CREATE POLICY "students can read event competences" ON event_competences AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"student"');

