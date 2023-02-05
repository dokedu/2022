CREATE POLICY entires_rls ON entries AS permissive
    FOR ALL
        USING is_allowed_to_crud_entry (account_id)
        WITH CHECK is_allowed_to_crud_entry (account_id);

