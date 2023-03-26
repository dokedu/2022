CREATE POLICY "educators can crud their entry tags" ON entry_tags AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"educator"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"educator"');

-- TODO: their
