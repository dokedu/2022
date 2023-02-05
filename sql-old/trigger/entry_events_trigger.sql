CREATE TRIGGER entry_events_trigger
    BEFORE INSERT OR UPDATE ON entry_events
    FOR EACH ROW
    EXECUTE PROCEDURE entry_events_trigger ();

