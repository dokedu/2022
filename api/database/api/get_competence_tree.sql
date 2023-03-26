CREATE OR REPLACE FUNCTION get_competence_tree (_competence_id text)
    RETURNS TABLE (
        id text,
        name text,
        competence_type text,
        grades int[],
        competence_id text,
        created_at timestamptz)
    LANGUAGE plpgsql
    SET search_path = 'public'
    SECURITY DEFINER
    AS $$
DECLARE
    _base_competence_org_id text;
BEGIN
    SELECT
        organisation_id INTO _base_competence_org_id
    FROM
        competences
    WHERE
        competences.id = _competence_id;
    assert _base_competence_org_id IN (
        SELECT
            identity_organisation_ids ())
        OR current_setting('request.jwt.claim.role', TRUE) = 'service_role',
        'competence not found';
    -- expect that if the user is allowed to see the base competence, they are also allowed to see the parents.
    RETURN query WITH RECURSIVE tree (
        id,
        name,
        competence_type,
        grades,
        competence_id,
        created_at
) AS (
        SELECT
            n.id,
            n.name,
            n.competence_type,
            n.grades,
            n.competence_id,
            n.created_at
        FROM
            competences n
        WHERE
            n.id = _competence_id
        UNION ALL
        SELECT
            n.id,
            n.name,
            n.competence_type,
            n.grades,
            n.competence_id,
            n.created_at
        FROM
            competences n
            JOIN tree t ON (n.id = t.competence_id))
    SELECT
        *
    FROM
        tree;
END
$$;

