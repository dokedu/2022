create table tags
(
    id              text      not null primary key default nanoid(),
    name            text      not null,
    organisation_id text      not null references organisations (id),
    created_by      text      not null references accounts (id),
    created_at      timestamptz not null             default now(),
    deleted_at      timestamptz                      default null,

    unique (name, organisation_id)
);

create table entry_tags
(
    id              text not null primary key default nanoid(),
    entry_id        text not null references entries (id),
    tag_id          text not null references tags (id),
    organisation_id text not null references organisations (id),
    created_at      timestamptz not null             default now(),
    deleted_at      timestamptz                      default null,

    unique (id, entry_id, tag_id)
);

create function tags_cu_trigger() returns trigger
    set search_path = public
    security definer
    language plpgsql as
$$
declare
    created_by_organisation_id text;
begin
    -- make sure that the tag and the account "created_by" are in the same organisation
    select organisation_id into created_by_organisation_id from accounts where id = new.created_by;

    if (new.organisation_id != created_by_organisation_id) then
        raise exception 'Tag and account "created_by" must be in the same organisation';
    end if;

    -- created_by must be one of the accounts from the current user
    if (new.created_by not in (select identity_account_ids())) then
        raise exception 'Tag "created_by" must be one of the accounts from the current user';
    end if;

    return new;
end;
$$;

create trigger tags_cu_trigger
    before insert or update
    on tags
    for each row
execute procedure tags_cu_trigger();

create function entry_tags_cu_trigger() returns trigger
    set search_path = public
    security definer
    language plpgsql as
$$
declare
    entry_organisation_id text;
    tag_organisation_id   text;
begin
    -- make sure that the entry, the tag, and the entry_tag are in the same organisation
    select a.organisation_id
    into entry_organisation_id
    from entries e
             inner join accounts a on a.id = e.account_id
    where e.id = new.entry_id;

    select organisation_id into tag_organisation_id from tags where id = new.tag_id;

    if (new.organisation_id != entry_organisation_id or new.organisation_id != tag_organisation_id) then
        raise exception 'Entry, tag and entry_tag must be in the same organisation';
    end if;

    return new;
end;
$$;

create trigger entry_tags_cu_trigger
    before insert or update
    on entry_tags
    for each row
execute procedure entry_tags_cu_trigger();

-- rls
alter table tags enable row level security;
alter table entry_tags enable row level security;

-- teacher, admin, owner are allowed to crud tags for their own organisation
create policy "teacher,admin,owner crud tags"
    on tags
    for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher}'::text[])));

-- whole organisation can read tags
create policy "read tags"
    on tags
    for select
    using (organisation_id in (select identity_organisation_ids()));


-- guest_teacher, teacher, admin, owner are allowed to crud entry_tags for their own organisation
create policy "guest_teacher,teacher,admin,owner crud entry_tags"
    on entry_tags
    for all
    using (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher,teacher_guest}'::text[])))
    with check (organisation_id in (select identity_organisation_ids_role('{owner,admin,teacher,teacher_guest}'::text[])));

