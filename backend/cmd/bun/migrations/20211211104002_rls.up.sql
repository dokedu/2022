revoke all on bun_migrations from anon;
revoke all on bun_migrations from authenticated;
revoke all on bun_migration_locks from anon;
revoke all on bun_migration_locks from authenticated;

alter table public.organisations
    enable row level security;
alter table public.identities
    enable row level security;
alter table public.accounts
    enable row level security;
alter table public.entries
    enable row level security;
alter table public.entry_accounts
    enable row level security;
alter table public.competences
    enable row level security;
alter table public.entry_account_competences
    enable row level security;
alter table public.entry_files
    enable row level security;
alter table public.events
    enable row level security;
alter table public.entry_events
    enable row level security;
alter table public.reports
    enable row level security;
alter table public.addresses
    enable row level security;
alter table public.event_competences
    enable row level security;


create policy "users can get their identities"
    on public.identities for select
    using (user_id = auth.uid());

create policy "identities can get their organisations"
    on public.organisations for select
    using (id in (select identity_organisation_ids()));

create policy "identities can get their accounts"
    on public.accounts for select
    using (id in (select identity_account_ids()));


create policy "owner,admin can crud accounts in their organisations"
    on public.accounts for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])));

create policy "everyone can read accounts in their organisations"
    on public.accounts for select
    using (organisation_id in (select identity_organisation_ids()));

create or replace function is_allowed_to_crud_entry(_entry_account_id text) returns bool
    security definer set search_path = 'public'
    language plpgsql as
$$
declare
    _author accounts;
begin
    -- get the organisation of the entry
    select a.* into _author from accounts a where a.id = _entry_account_id limit 1;

    -- check if the user is the author of the entry
    if (_author.id in (select identity_account_ids_role('{owner, admin, teacher}'::text[]))) then
        return true;
    end if;

    -- check if the user is owner or admin in the organisation
    if (_author.organisation_id in (select identity_organisation_ids_role('{owner, admin}'::text[]))) then
        return true;
    end if;

    return false;
end;
$$;

create policy "entires_rls" on public.entries for all
    using (is_allowed_to_crud_entry(account_id))
    with check (is_allowed_to_crud_entry(account_id));

--todo: might be insecure for teacher
create policy "owner,admin,teacher can manage entry_accounts"
    on public.entry_accounts for all
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
    using (
        account_id in
        (select id
         from accounts a
         where a.id = entry_accounts.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    )
    with check (
        account_id in
        (select id
         from accounts a
         where a.id = entry_accounts.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    );

create policy "everyone can read competences"
    on public.competences for select
    using (organisation_id in (select identity_organisation_ids()));

create policy "owner,admin can crud competences"
    on public.competences for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin}'::text[])));

-- todo insecure for teacher
create policy "owner,admin,teacher can manage entry_account_competences"
    on public.entry_account_competences for all
    -- since account.organisation == entry.organisation (due to trigger), we can just check account.
    using (
        account_id in
        (select id
         from accounts a
         where a.id = entry_account_competences.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    )
    with check (
        account_id in
        (select id
         from accounts a
         where a.id = entry_account_competences.account_id
           and organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    );

create policy "everyone in the organisation can read files"
    on storage.objects for select
    using (bucket_id in (select concat('org_', identity_organisation_ids())));

create policy "everyone in the organisation can upload files"
    on storage.objects for insert with check (bucket_id in (select concat('org_', identity_organisation_ids())));

--todo: this is not right.
create policy "owner,admin,teacher can manage entry_files"
    on public.entry_files for all
    using (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    )
    with check (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    );


create policy "owner,admin,teacher can manage events"
    on public.events for all
    using (
        organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );

-- todo: respect teacher roles
create policy "owner,admin,teacher can manage entry_events"
    on public.entry_events for all
    using (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    )
    with check (exists(
        (select entries.id
         from entries
                  inner join accounts a on a.id = account_id and a.organisation_id in
                                                                 (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
         where entries.id = entry_id))
    );

create policy "owner,admin,teacher can manage reports"
    on public.reports for all
    using (
        (select a.organisation_id
         from accounts a
         where a.id = account_id) in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        (select a.organisation_id
         from accounts a
         where a.id = account_id) in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );

-- todo: respect teacher roles
create policy "owner,admin,teacher can manage event_competences"
    on public.event_competences for all
    using (
        (select organisation_id
         from events
         where id = event_competences.event_id) in
        (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    )
    with check (
        (select organisation_id
         from events
         where id = event_competences.event_id) in
        (select identity_organisation_ids_role('{owner,admin,teacher}'::text[]))
    );


-- bucket policy
create policy "everyone from the organisation can crud the bucket" on storage.buckets for all
    using (
        trim(leading 'org_' from buckets.name) in (select identity_organisation_ids())
    )
    with check (
        trim(leading 'org_' from buckets.name) in (select identity_organisation_ids())
    );