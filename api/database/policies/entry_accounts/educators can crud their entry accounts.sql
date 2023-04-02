CREATE POLICY "educators can crud their entry accounts" ON entry_accounts AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"educators"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"educators"');

-- TODO: their
