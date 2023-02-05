CREATE CONSTRAINT TRIGGER competences_trigger
    AFTER INSERT OR UPDATE ON competences DEFERRABLE
    FOR EACH ROW
    EXECUTE PROCEDURE competences_trigger ();

