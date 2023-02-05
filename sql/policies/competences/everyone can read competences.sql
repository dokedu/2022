-- everyone can read competences in their organisation
CREATE POLICY "everyone can read competences" ON competences AS permissive
    FOR SELECT
        USING (TRUE);

