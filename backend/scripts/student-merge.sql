-- this script can be used to merge two students, if they have been duplicated on accident.
-- it requires, that both accounts are from the same organisation, that from is marked as deleted.
-- it will update reports, entry_accounts and entry_account_competences and replace from with to.
-- afterwards, it hard-deletes the from student.
create or replace function pg_temp.merge_students(from_account_id text, to_account_id text)
    returns void
    language plpgsql
    set search_path = 'public' as
$$
declare
    from_account     accounts;
    to_account       accounts;
    from_account_ea  int;
    to_account_ea    int;
    from_account_eac int;
    to_account_eac   int;
    from_reports     int;
    to_reports       int;
begin
    select * into from_account from accounts where id = from_account_id;
    select * into to_account from accounts where id = to_account_id;

    if from_account is null or to_account is null then
        raise exception 'could not find students';
    end if;

    if from_account.deleted_at is null then
        raise exception 'from_account must be deleted';
    end if;

    if to_account.deleted_at is not null then
        raise exception 'to_account must not be deleted';
    end if;

    if from_account.organisation_id != to_account.organisation_id then
        raise exception 'cannot migrate across two organisations';
    end if;

    if from_account.first_name != to_account.first_name or from_account.last_name != to_account.last_name then
        raise exception 'first_name and last_name must be the same';
    end if;

    if from_account.role != 'student' or to_account.role != 'student' then
        raise exception 'can only migrate students';
    end if;

    -- start by printing info about both students.
    raise notice 'migrating student %s to %s', from_account.id, to_account.id;

    select count(*) into from_account_ea from entry_accounts where account_id = from_account.id;
    select count(*) into to_account_ea from entry_accounts where account_id = to_account.id;
    select count(*) into from_account_eac from entry_account_competences where account_id = from_account.id;
    select count(*) into to_account_eac from entry_account_competences where account_id = to_account.id;
    select count(*) into from_reports from reports where reports.student_account_id = from_account.id;
    select count(*) into to_reports from reports where reports.student_account_id = to_account.id;

    raise notice 'from student has %, %, %', from_account_ea, from_account_eac, from_reports;
    raise notice 'to   student has %, %, %', to_account_ea, to_account_eac, to_reports;


    -- do the actual migration for the student

    -- if there are any duplicates between them two, delete the old ones.
    set local app.hard_delete = 'on';

    -- idea: duplicates are entry_account_competences among the two accounts where entry_id and competence_id are the same
    with duplicates as (select entry_id, competence_id
                        from entry_account_competences
                        where account_id = from_account.id
                           or account_id = to_account.id
                        group by (entry_id, competence_id)
                        having count(*) > 1),
         -- for those pairs of duplicates, find the id of the eac where account = from
         to_delete as (select id
                       from entry_account_competences ea
                                inner join duplicates d
                                           on ea.entry_id = d.entry_id and ea.competence_id = d.competence_id and
                                              ea.account_id = from_account.id)
         -- and delete those
    delete
    from entry_account_competences
    where id in (select * from to_delete)
      and account_id = from_account.id;

    -- duplicates are where entry_id is the same. find those
    with duplicate as (select entry_id
                       from entry_accounts
                       where account_id = from_account.id
                          or account_id = to_account.id
                       group by (entry_id)
                       having count(*) > 1)
         -- delete those entries for the from_account.
    delete
    from entry_accounts
    where account_id = from_account.id
      and entry_id in (select * from duplicate);

    set local app.hard_delete = 'off';

    -- migrate data
    update entry_accounts set account_id = to_account.id where account_id = from_account.id;
    update entry_account_competences set account_id = to_account.id where account_id = from_account.id;
    update reports set student_account_id = to_account.id where student_account_id = from_account.id;


    -- print logs again
    select count(*) into from_account_ea from entry_accounts where account_id = from_account.id;
    select count(*) into to_account_ea from entry_accounts where account_id = to_account.id;
    select count(*) into from_account_eac from entry_account_competences where account_id = from_account.id;
    select count(*) into to_account_eac from entry_account_competences where account_id = to_account.id;
    select count(*) into from_reports from reports where reports.student_account_id = from_account.id;
    select count(*) into to_reports from reports where reports.student_account_id = to_account.id;

    raise notice 'from student has %, %, %', from_account_ea, from_account_eac, from_reports;
    raise notice 'to   student has %, %, %', to_account_ea, to_account_eac, to_reports;

    -- delete old account
    set local app.hard_delete = 'on';
    delete from accounts where id = from_account.id;
    set local app.hard_delete = 'off';
end;
$$;