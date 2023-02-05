CREATE POLICY "owners can crud entry tags" ON entry_tags AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"owner"');

