CREATE VIEW view_entries (id, date, body, account_id, created_at, deleted_at) AS
WITH org_ids AS MATERIALIZED (
    SELECT
        identity_organisation_ids_role (
            '{owner,admin,teacher}'::text[]
) AS identity_organisation_ids_role
)
SELECT
    e.id,
    e.date,
    e.body,
    e.account_id,
    e.created_at,
    e.deleted_at
FROM
    entries e
    JOIN accounts a ON a.id = e.account_id
WHERE (a.organisation_id IN (
        SELECT
            org_ids.identity_organisation_ids_role
        FROM
            org_ids));

