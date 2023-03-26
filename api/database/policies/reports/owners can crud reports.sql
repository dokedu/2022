CREATE POLICY "owners can crud reports" ON reports AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"owner"');

