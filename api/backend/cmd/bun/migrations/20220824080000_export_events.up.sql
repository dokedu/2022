create or replace function export_events(_organisation_id text, _from date, _to date, _show_archived bool)
    returns TABLE
            (
                id        text,
                title     text,
                body      text,
                starts_at timestamptz,
                ends_at   timestamptz,
                subjects  jsonb
            )
    security definer
    set search_path = "public"
    language plpgsql
as
$$
begin
    -- check that the user has rights to export for this organisation
    assert _organisation_id in (select identity_organisation_ids()) or
           current_setting('request.jwt.claim.role', true) = 'service_role', 'organisation not found';

    return query
        -- get all competences which are linked to events. this can happen from two ways.
        -- they are de-duplicated via distinct union & selection.
        with _competences as (
            -- way 1: directly linked via event event_competences>competences
            select distinct on (e.id, c.id) e.id as event_id,
                                            c.id,
                                            c.name,
                                            c.competence_id,
                                            c.grades
            from events e
                     inner join event_competences ec on e.id = ec.event_id
                     inner join competences c on ec.competence_id = c.id
            where e.organisation_id = _organisation_id
              and e.starts_at >= _from
              and e.ends_at <= _to
              and (_show_archived or e.deleted_at is null)
              and c.deleted_at is null
              -- union both ways.
            union
            distinct
            -- way 2: indirect via entry_events>events>eac>competences
            select distinct on (e.id, c.id) e.id, c.id, c.name, c.competence_id, c.grades
            from events e
                     inner join entry_events ee on e.id = ee.event_id
                     inner join entries en on ee.entry_id = en.id
                     inner join entry_account_competences eac on en.id = eac.entry_id
                     inner join competences c on eac.competence_id = c.id
            where e.organisation_id = _organisation_id
              and e.starts_at >= _from
              and e.ends_at <= _to
              and (_show_archived or e.deleted_at is null)
              and en.deleted_at is null
              and eac.deleted_at is null
              and c.deleted_at is null),

             -- next, for each found competence, fetch the whole competence tree
             _competence_trees as (select c.event_id,
                                          c.id,
                                          c.name,
                                          c.competence_id,
                                          c.grades,
                                          jsonb_agg(b) as competence_tree
                                   from _competences c,
                                        -- use lateral subquery (to get all rows from the function)
                                        lateral (select * from get_competence_tree(c.id)) b
                                        -- since the lateral subquery produces multiple rows, we need to group by & use json aggregation
                                   group by c.event_id, c.id, c.name, c.competence_id, c.grades),

             -- for each found competence, fetch the subject (last entry in competence tree).
             -- we then group them by subject, and store the competences using the jsonb_agg
             _subjects as (select ct.event_id,
                                  jsonb_array_element(ct.competence_tree,
                                                      jsonb_array_length(ct.competence_tree) - 1) ->
                                  'id'          as subject_id,
                                  jsonb_array_element(ct.competence_tree,
                                                      jsonb_array_length(ct.competence_tree) - 1) ->
                                  'name'        as subject_name,
                                  jsonb_agg(ct) as competences
                           from _competence_trees ct
                           group by ct.event_id, subject_id, subject_name)
             -- finally, using all of this info, we can run the main query. select all events again, and group by event so
             -- all of their found subjects land in a final jsonb_agg.
        select e.id,
               e.title,
               e.body,
               e.starts_at,
               e.ends_at,
               jsonb_agg(s) FILTER ( WHERE s is not null ) as subjects
        from events e
                 left join _subjects s on e.id = s.event_id
        where e.organisation_id = _organisation_id
          and e.starts_at >= _from
          and e.ends_at <= _to
          and (_show_archived or e.deleted_at is null)
        group by e.id, e.title
        order by e.ends_at;
end;
$$;