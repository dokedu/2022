CREATE TRIGGER accounts_trigger
    BEFORE INSERT OR UPDATE ON accounts
    FOR EACH ROW
    EXECUTE PROCEDURE accounts_trigger ();

