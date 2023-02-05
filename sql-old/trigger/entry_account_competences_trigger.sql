CREATE TRIGGER entry_account_competences_trigger
    BEFORE INSERT OR UPDATE ON entry_account_competences
    FOR EACH ROW
    EXECUTE PROCEDURE entry_account_competences_trigger ();

