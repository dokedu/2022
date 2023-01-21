create or replace function entry_accounts_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id text;
    entry_org_id   text;
begin
    -- make sure that account and entry are from the same organisation
    select organisation_id into account_org_id from accounts where id = new.account_id;
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    assert account_org_id = entry_org_id, 'entry and account are not from the same organisation';
    return new;
end
$$;
create trigger entry_accounts_trigger
    before insert or update
    on entry_accounts
    for each row
execute function entry_accounts_trigger();

create or replace function entry_account_competences_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id    text;
    entry_org_id      text;
    competence_org_id text;
begin
    -- make sure that account and entry are from the same organisation
    select organisation_id into account_org_id from accounts where id = new.account_id;
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;
    select c.organisation_id into competence_org_id from competences c where c.id = new.competence_id;

    assert account_org_id = entry_org_id, 'entry, account and competence are not from the same organisation';
    assert account_org_id = competence_org_id, 'entry, account and competence are not from the same organisation';
    return new;
end
$$;
create trigger entry_account_competences_trigger
    before insert or update
    on entry_account_competences
    for each row
execute function entry_account_competences_trigger();

create or replace function entry_files_trigger() returns trigger
    language plpgsql as
$$
declare
    entry_org_id text;
begin
    select a.organisation_id
    into entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    assert new.file_bucket_id = concat('org_', entry_org_id), 'entry, file are not from the same organisation';
    return new;
end
$$;
create trigger entry_files_trigger
    before insert or update
    on entry_files
    for each row
execute function entry_files_trigger();

create or replace function entry_events_trigger() returns trigger
    language plpgsql as
$$
declare
    _entry_org_id           text;
    declare _event_org_id text;
begin
    select a.organisation_id
    into _entry_org_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;
    select p.organisation_id into _event_org_id from events p where p.id = new.event_id;

    assert _entry_org_id = _event_org_id, 'entry and event are not from the same organisation';
    return new;
end
$$;
create trigger entry_events_trigger
    before insert or update
    on entry_events
    for each row
execute function entry_events_trigger();

create or replace function reports_trigger() returns trigger
    language plpgsql as
$$
declare
    account_org_id text;
    student_org_id text;
begin
    select organisation_id
    into account_org_id
    from accounts
    where id = new.account_id;

    if new.file_bucket_id is not null then
        assert new.file_bucket_id = concat('org_', account_org_id), 'report, file are not from the same organisation';
    end if;

    select organisation_id
    into student_org_id
    from accounts
    where id = new.student_account_id;

    assert account_org_id = student_org_id, 'account and student are not from the same organisation';

    return new;
end
$$;
create trigger reports_trigger
    before insert or update
    on public.reports
    for each row
execute function reports_trigger();

create or replace function report_files_trigger() returns trigger
    language plpgsql as
$$
BEGIN
    perform pg_notify('app.report_created', NEW.id);
    RETURN new;
END;
$$;
create trigger new_report_trigger
    after insert
    on public.reports
    for each row
execute procedure report_files_trigger();

create or replace function competences_trigger() returns trigger
    language plpgsql as
$$
declare
    competence_parent_org_id text;
begin
    if new.competence_id is null then
        return new;
    end if;

    select organisation_id
    into competence_parent_org_id
    from public.competences
    where id = new.competence_id;

    assert new.organisation_id = competence_parent_org_id, 'competence and competence parent are not from the same organisation';
    return new;
end
$$;

create constraint trigger competences_trigger
    after insert or update
    on public.competences
    deferrable
    for each row
execute function competences_trigger();

create or replace function event_competences_trigger() returns trigger
    language plpgsql as
$$
declare
    event_org_id    text;
    competence_org_id text;
begin
    select organisation_id
    into event_org_id
    from events
    where id = new.event_id;

    select organisation_id
    into competence_org_id
    from competences
    where id = new.competence_id;

    assert competence_org_id = event_org_id, 'event, competence are not from the same organisation';
    return new;
end
$$;
create trigger event_competences_trigger
    before insert or update
    on public.event_competences
    for each row
execute function event_competences_trigger();

create or replace function accounts_trigger() returns trigger
    language plpgsql as
$$
begin
    if new.avatar_file_bucket_id is not null then
        assert new.avatar_file_bucket_id = concat('org_', new.organisation_id), 'account, file are not from the same organisation';
    end if;

    return new;
end
$$;
create trigger accounts_trigger
    before insert or update
    on public.accounts
    for each row
execute function accounts_trigger();

create or replace function deleted_at_trigger() returns trigger
    language plpgsql as
$$
begin
    execute 'UPDATE ' || tg_table_name || ' SET deleted_at = now() where id = ''' || old.id || '''';
    return null;
end
$$;

-- create trigger on all tables that have a deleted_at column
do language plpgsql
$$
    declare
        t      text;
        tables text[] := array ['accounts', 'addresses', 'competences', 'entries', 'entry_account_competences', 'entry_accounts', 'entry_files', 'entry_events', 'identities', 'organisations', 'events', 'event_competences', 'reports'];
    begin
        foreach t in array tables
            loop
                execute 'create trigger deleted_at_trigger before delete on public.' || t ||
                        ' for each row when (coalesce(current_setting(''app.hard_delete'', true), ''off'') <> ''on'') execute function deleted_at_trigger();';
            end loop;
    end
$$;
