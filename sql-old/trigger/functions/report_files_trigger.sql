CREATE FUNCTION report_files_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM
        pg_notify('app.report_created', NEW.id);
    RETURN new;
END;
$$;

