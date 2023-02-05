CREATE TRIGGER event_competences_trigger
    BEFORE INSERT OR UPDATE ON event_competences
    FOR EACH ROW
    EXECUTE PROCEDURE event_competences_trigger ();

