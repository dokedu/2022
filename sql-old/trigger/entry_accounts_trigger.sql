CREATE TRIGGER entry_accounts_trigger
    BEFORE INSERT OR UPDATE ON entry_accounts
    FOR EACH ROW
    EXECUTE PROCEDURE entry_accounts_trigger ();

