create or replace function is_allowed_to_crud_entry(_entry_account_id text) returns boolean
    security definer
    SET search_path = public
    language plpgsql
as
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

    -- check if the user is owner, admin or teacher in the organisation
    if (_author.organisation_id in (select identity_organisation_ids_role('{owner, admin, teacher}'::text[]))) then
        return true;
    end if;

    return false;
end;
$$;