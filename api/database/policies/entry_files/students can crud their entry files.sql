CREATE POLICY "students can crud their entry files" ON entry_files AS permissive
    FOR ALL
        USING (get_my_claim ('dokedu_organisation_role') = '"student"'
            AND get_my_claim ('dokedu_account_id') = entry_files.student_id)
            WITH CHECK (get_my_claim ('dokedu_organisation_role') = '"student"'
            AND get_my_claim ('dokedu_account_id') = entry_files.student_id);

-- TODO: their (above might be wrong, but it's a start)
