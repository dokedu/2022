CREATE POLICY "owners can crud their addresses" ON addresses AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"owner"');

-- TODO: their
