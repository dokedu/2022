create index on entry_accounts (account_id);
alter table reports
    drop constraint reports_type_check,
    add constraint reports_type_check
        check (type in ('report', 'subjects', 'report_docx'));