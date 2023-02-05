CREATE TRIGGER entry_files_trigger
    BEFORE INSERT OR UPDATE ON entry_files
    FOR EACH ROW
    EXECUTE PROCEDURE entry_files_trigger ();

