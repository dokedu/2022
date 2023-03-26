CREATE VIEW view_entries AS (
    WITH org_ids AS MATERIALIZED (
        SELECT
            identity_organisation_ids_role (
                '{owner, admin, teacher}'::text[] -- todo: add guest teacher
))
        SELECT
            e.*
        FROM
            entries e
            INNER JOIN accounts a ON a.id = e.account_id
        WHERE
            a.organisation_id IN (
                SELECT
                    *
                FROM
                    org_ids));

