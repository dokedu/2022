ALTER TABLE "public"."event_competences"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."entry_files"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."entry_events"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."entry_accounts"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."entry_account_competences"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."entries"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

ALTER TABLE "public"."reports"
    ADD COLUMN "organisation_id" text NOT NULL REFERENCES organisations (id);

