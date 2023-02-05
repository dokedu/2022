CREATE TRIGGER reports_trigger
    BEFORE INSERT OR UPDATE ON reports
    FOR EACH ROW
    EXECUTE PROCEDURE reports_trigger ();

