CREATE POLICY "teachers can crud entry accounts" ON entry_accounts AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"teacher"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"teacher"');

