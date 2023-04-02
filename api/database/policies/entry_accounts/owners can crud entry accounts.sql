CREATE POLICY "owners can crud entry accounts" ON entry_accounts AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"owner"');

