CREATE POLICY "guest_teacher,teacher,admin,owner crud entry_tags" ON entry_tags AS permissive
    FOR ALL
        USING (organisation_id IN (
            SELECT
                identity_organisation_ids_role ('{owner,admin,teacher,teacher_guest}'::text[]) AS identity_organisation_ids_role))
                WITH CHECK (organisation_id IN (
                    SELECT
                        identity_organisation_ids_role ('{owner,admin,teacher,teacher_guest}'::text[]) AS identity_organisation_ids_role));

