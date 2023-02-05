CREATE POLICY "owners can update their organisation" ON organisations AS permissive
    FOR UPDATE
        USING (get_my_claim ('dokedu_role') = '"owner"')
        WITH CHECK (get_my_claim ('dokedu_role') = '"owner"');

