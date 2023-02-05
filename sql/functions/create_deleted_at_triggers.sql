CREATE OR REPLACE FUNCTION deleted_at_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE 'UPDATE ' || tg_table_name || ' SET deleted_at = now() where id = ''' || OLD.id || '''';
    RETURN NULL;
END
$$;

-- create trigger on all tables that have a deleted_at column
DO
LANGUAGE plpgsql
$$ DECLARE t text;

tables text[] := ARRAY['accounts', 'addresses', 'competences', 'entries', 'entry_account_competences', 'entry_accounts', 'entry_files', 'entry_events', 'identities', 'organisations', 'events', 'event_competences', 'reports'];

BEGIN
    foreach t IN ARRAY tables LOOP
        EXECUTE 'create or replace trigger deleted_at_trigger before delete on public.' || t || ' for each row when (coalesce(current_setting(''app.hard_delete'', true), ''off'') <> ''on'') execute function deleted_at_trigger();';

END LOOP;

END $$;

