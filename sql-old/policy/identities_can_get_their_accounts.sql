CREATE POLICY "identities can get their accounts" ON accounts AS permissive
    FOR SELECT
        USING (id IN (
            SELECT
                identity_account_ids () AS identity_account_ids));

