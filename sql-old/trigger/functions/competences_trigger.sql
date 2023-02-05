CREATE FUNCTION competences_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    competence_parent_org_id text;
BEGIN
    IF NEW.competence_id IS NULL THEN
        RETURN new;
    END IF;
    SELECT
        organisation_id INTO competence_parent_org_id
    FROM
        public.competences
    WHERE
        id = NEW.competence_id;
    assert NEW.organisation_id = competence_parent_org_id,
    'competence and competence parent are not from the same organisation';
    RETURN new;
END
$$;

