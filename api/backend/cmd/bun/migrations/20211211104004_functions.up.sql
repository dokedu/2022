create or replace function get_competence_tree(_competence_id text) returns table(id text, name text, competence_type text, grades int[], competence_id text, created_at timestamptz) language plpgsql set search_path = 'public' security definer as $$
declare
    _base_competence_org_id text;
    begin

    select organisation_id into _base_competence_org_id from competences where competences.id = _competence_id;
    assert _base_competence_org_id in (select identity_organisation_ids()) or current_setting('request.jwt.claim.role', true) = 'service_role', 'competence not found';

    -- expect that if the user is allowed to see the base competence, they are also allowed to see the parents.
    return query with recursive tree(id, name, competence_type, grades, competence_id, created_at) as (
            select n.id, n.name, n.competence_type, n.grades, n.competence_id, n.created_at
            from competences n
            where n.id = _competence_id
            union all
            select n.id, n.name, n.competence_type, n.grades, n.competence_id, n.created_at
            from competences n
                     join tree t on (n.id = t.competence_id)
        )
        select *
        from tree;
end
    $$;