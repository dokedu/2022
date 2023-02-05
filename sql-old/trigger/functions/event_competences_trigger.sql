CREATE FUNCTION event_competences_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    event_org_id text;
    competence_org_id text;
BEGIN
    SELECT
        organisation_id INTO event_org_id
    FROM
        events
    WHERE
        id = NEW.event_id;
    SELECT
        organisation_id INTO competence_org_id
    FROM
        competences
    WHERE
        id = NEW.competence_id;
    assert competence_org_id = event_org_id,
    'event, competence are not from the same organisation';
    RETURN new;
END
$$;

