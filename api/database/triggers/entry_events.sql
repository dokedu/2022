-- assert entry and event are from the same organisation
CREATE TRIGGER entry_events_trigger
    BEFORE INSERT OR UPDATE ON entry_events
    FOR EACH ROW
    EXECUTE PROCEDURE entry_events_trigger ();

CREATE FUNCTION entry_events_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    _entry_org_id text;
    DECLARE _event_org_id text;
BEGIN
    SELECT
        a.organisation_id INTO _entry_org_id
    FROM
        entries e
        INNER JOIN accounts a ON a.id = e.account_id
    WHERE
        e.id = NEW.entry_id;
    SELECT
        p.organisation_id INTO _event_org_id
    FROM
        events p
    WHERE
        p.id = NEW.event_id;
    assert _entry_org_id = _event_org_id,
    'entry and event are not from the same organisation';
    RETURN new;
END
$$;

