CREATE TABLE public.account_competences
(
    id              text        NOT NULL PRIMARY KEY DEFAULT nanoid(),
    level           int         NOT NULL CHECK ( level <= 3 AND level >= 0),
    student_id      text        NOT NULL REFERENCES public.accounts (id),
    account_id      text        NOT NULL REFERENCES public.accounts (id),
    competence_id   text        NOT NULL REFERENCES public.competences (id),
    organisation_id text        NOT NULL REFERENCES public.organisations (id),
    created_at      timestamptz NOT NULL             DEFAULT NOW(),
    deleted_at      timestamptz NULL                 DEFAULT NULL
);

CREATE INDEX ON public.account_competences (deleted_at) WHERE deleted_at IS NULL;

ALTER TABLE public.account_competences
    ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner,admin,teacher can manage account_competences"
    ON public.account_competences FOR
    ALL USING (organisation_id IN (SELECT identity_organisation_ids_role('{owner,admin,teacher}'::text[])))
    WITH CHECK (organisation_id IN (SELECT identity_organisation_ids_role('{owner,admin,teacher}'::text[])));