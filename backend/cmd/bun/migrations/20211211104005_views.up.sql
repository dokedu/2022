create view view_entries as
(
with org_ids as materialized (select identity_organisation_ids_role('{owner, admin, teacher}'::text[]))
select e.* from entries e
  inner join accounts a on a.id = e.account_id
where a.organisation_id in (select * from org_ids)
);