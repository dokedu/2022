CREATE TRIGGER new_report_trigger
    AFTER INSERT ON reports
    FOR EACH ROW
    EXECUTE PROCEDURE report_files_trigger ();

