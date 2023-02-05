CREATE TRIGGER entry_tags_cu_trigger
    BEFORE INSERT OR UPDATE ON entry_tags
    FOR EACH ROW
    EXECUTE PROCEDURE entry_tags_cu_trigger ();

