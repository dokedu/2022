CREATE POLICY "educators can read tags" ON tags AS permissive
    FOR SELECT
        USING (get_my_claim ('dokedu_organisation_role') = '"educator"');

