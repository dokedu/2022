# SQL

## To Do's

- script that adds/deprecates [policies|triggers]/{table_name} folder and files
- script to generate a schema.sql for the logic layer (header that removes all existing logic, which we could later optimize to detect changes and update only relevant parts, also run it in a transaction and notify postgrest afterwords)

## Data vs. Logic Layer

Every time we change a function, we run a replace/update for that function.

Initially, on each commit/deploy, we can drop all functions/triggers/policies and run all files in this folder.

Things to consider: downtime (i.e. when running this, a user might be able to do something we don't want because the function no longer exists/changed without all changes being merged/completed). So we probably need to wrap it all into one big transaction?

In general, we want to separate the data layer from the logic layer. The data layer may have less changes than the logic layer and we want to keep the developer expierence as good as possible.

The data-layer is changed by migrations as usual. We can create a schema.sql file that has the current state of the data layer to allow easier local development/inspection for developers.

## Claims

- refactor Dokedu to support one user per organisation (no one besides Tom ever used the multi org feature)
  - remove `public.identities`
  - migrate to claims [more here](https://github.com/supabase-community/supabase-custom-claims)
    - `organisation_id: nanoid`
    - `role: [owner, admin, teacher, educator, student, parent]`

- only allow trusted domains for organisations

- add `domains: text[]` to `organisations`
- on insert and update organisation_id then check wether domain is within org.domains

- refactor rls to use new claim system
- refactor tests to validate *everything* works as expected

- update invite user feature

---

> PostgREST allows us to specify a stored procedure to run during attempted authentication. The function can do whatever it likes, including raising an exception to terminate the request. [ref](https://postgrest.org/en/stable/tutorials/tut1.html#bonus-topic-immediate-revocation)

If we changed a claim, we could insert the change into a history table of claims. So on every query we could check if a claim has been updated recently. We could also make it a materialized view to allow postgres to cache this view and only update the view when we actually change data.

Actually, could we use this materialized view to store policies, i.e. like an ACL permission table?
