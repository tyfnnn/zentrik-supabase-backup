alter table "public"."accounts" drop constraint "accounts_account_number_key";

drop index if exists "public"."accounts_account_number_key";

alter table "public"."accounts" alter column "organization_id" drop not null;

CREATE UNIQUE INDEX accounts_unique_number_per_org ON public.accounts USING btree (account_number, organization_id) NULLS NOT DISTINCT;

CREATE INDEX idx_accounts_global_templates ON public.accounts USING btree (account_number) WHERE (organization_id IS NULL);

CREATE INDEX idx_accounts_organization_id ON public.accounts USING btree (organization_id) WHERE (organization_id IS NOT NULL);

alter table "public"."accounts" add constraint "accounts_unique_number_per_org" UNIQUE using index "accounts_unique_number_per_org";


