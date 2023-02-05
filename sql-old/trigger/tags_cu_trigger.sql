CREATE TRIGGER tags_cu_trigger
    BEFORE INSERT OR UPDATE ON tags
    FOR EACH ROW
    EXECUTE PROCEDURE tags_cu_trigger ();

