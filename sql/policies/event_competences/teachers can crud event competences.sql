CREATE POLICY "teachers can crud event competences" ON event_competences AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"teacher"');

