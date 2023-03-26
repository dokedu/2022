-- assert entry, entry_tag and tag are from the same organisation
CREATE TRIGGER entry_tags_cu_trigger
    BEFORE INSERT OR UPDATE ON entry_tags
    FOR EACH ROW
    EXECUTE PROCEDURE entry_tags_cu_trigger ();

CREATE FUNCTION entry_tags_cu_trigger ()
    RETURNS TRIGGER
    SECURITY DEFINER
    SET search_path = public
    LANGUAGE plpgsql
    AS $$
DECLARE
    entry_organisation_id text;
    tag_organisation_id text;
BEGIN
    -- make sure that the entry, the tag, and the entry_tag are in the same organisation
    SELECT
        a.organisation_id INTO entry_organisation_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    SELECT
        organisation_id INTO tag_organisation_id
    FROM
        tags
    WHERE
        id = NEW.tag_id;
    IF (NEW.organisation_id != entry_organisation_id OR NEW.organisation_id != tag_organisation_id) THEN
        RAISE EXCEPTION 'Entry, tag and entry_tag must be in the same organisation';
    END IF;
    RETURN new;
END;
$$;

