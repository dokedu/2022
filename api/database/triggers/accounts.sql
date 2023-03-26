CREATE TRIGGER accounts_trigger
    BEFORE INSERT OR UPDATE ON accounts
    FOR EACH ROW
    EXECUTE PROCEDURE accounts_trigger ();

CREATE FUNCTION accounts_trigger ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.avatar_file_bucket_id IS NOT NULL THEN
        assert NEW.avatar_file_bucket_id = concat('org_', NEW.organisation_id),
        'account, file are not from the same organisation';
    END IF;
    RETURN new;
END
$$;

