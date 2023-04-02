CREATE POLICY "admins can crud entry accounts" ON entry_accounts AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"admin"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"admin"');

