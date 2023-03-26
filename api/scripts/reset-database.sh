#!/usr/bin/env bash

# check if we are in scripts folder
if [[ $PWD == *scripts ]]; then cd ..; fi
cd docker/ || exit

export PGPASSWORD=12341234
psql -h localhost -U postgres -c "truncate auth.users cascade; DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO dashboard_user; grant usage                     on schema public to postgres, anon, authenticated, service_role;alter default privileges in schema public grant all on tables to postgres, anon, authenticated, service_role;alter default privileges in schema public grant all on functions to postgres, anon, authenticated, service_role;alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role; DO \$\$DECLARE p pg_policies; BEGIN FOR p IN select * from pg_policies LOOP EXECUTE 'drop policy "' || p.policyname || '" on "' || p.schemaname || '"."' || p.tablename || '"'; END LOOP; END\$\$;";
