CREATE FUNCTION deleted_at_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE 'UPDATE ' || tg_table_name || ' SET deleted_at = now() where id = ''' || OLD.id || '''';
    RETURN NULL;
END
$$;

