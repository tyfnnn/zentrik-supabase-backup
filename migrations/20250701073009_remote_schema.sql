alter table "public"."projects" drop constraint "projects_budget_currency_code_fkey";

drop view if exists "public"."project_statistics";

alter table "public"."projects" drop column "budget_currency_code";

alter table "public"."projects" add column "budget_currency" character varying(3) default 'EUR'::character varying;

alter table "public"."projects" add column "currency_code" text not null;

alter table "public"."projects" add column "donor_name" character varying(200);

alter table "public"."projects" add column "responsible_user_id" uuid;

alter table "public"."projects" add column "total_budget" numeric(15,2) default 0;

alter table "public"."receipts" add column "account_id" uuid;

alter table "public"."receipts" add column "amount" numeric(15,2);

alter table "public"."receipts" add column "attachment_urls" text[];

alter table "public"."receipts" add column "currency" character varying(3) default 'EUR'::character varying;

alter table "public"."receipts" add column "image_path" text;

CREATE INDEX idx_accounts_active ON public.accounts USING btree (is_active);

CREATE INDEX idx_accounts_parent ON public.accounts USING btree (parent_account_id);

CREATE INDEX idx_projects_active ON public.projects USING btree (is_active);

CREATE INDEX idx_receipts_account ON public.receipts USING btree (account_id);

alter table "public"."accounts" add constraint "check_account_type" CHECK ((account_type = ANY (ARRAY['ASSET'::text, 'LIABILITY'::text, 'EXPENSE'::text, 'REVENUE'::text]))) not valid;

alter table "public"."accounts" validate constraint "check_account_type";

alter table "public"."accounts" add constraint "check_ngo_area" CHECK ((ngo_area = ANY (ARRAY['IDEELL'::text, 'VERMOEGEN'::text, 'ZWECK'::text, 'WIRTSCHAFT'::text]))) not valid;

alter table "public"."accounts" validate constraint "check_ngo_area";

alter table "public"."accounts" add constraint "fk_accounts_currency" FOREIGN KEY (currency_code) REFERENCES currencies(code) not valid;

alter table "public"."accounts" validate constraint "fk_accounts_currency";

alter table "public"."accounts" add constraint "fk_accounts_parent" FOREIGN KEY (parent_account_id) REFERENCES accounts(id) not valid;

alter table "public"."accounts" validate constraint "fk_accounts_parent";

alter table "public"."projects" add constraint "fk_projects_user" FOREIGN KEY (responsible_user_id) REFERENCES auth.users(id) not valid;

alter table "public"."projects" validate constraint "fk_projects_user";

alter table "public"."projects" add constraint "projects_currency_code_fkey" FOREIGN KEY (currency_code) REFERENCES currencies(code) not valid;

alter table "public"."projects" validate constraint "projects_currency_code_fkey";

alter table "public"."receipts" add constraint "fk_receipts_account" FOREIGN KEY (account_id) REFERENCES accounts(id) not valid;

alter table "public"."receipts" validate constraint "fk_receipts_account";

alter table "public"."receipts" add constraint "fk_receipts_approved_by" FOREIGN KEY (approved_by) REFERENCES auth.users(id) not valid;

alter table "public"."receipts" validate constraint "fk_receipts_approved_by";

alter table "public"."receipts" add constraint "fk_receipts_created_by" FOREIGN KEY (created_by) REFERENCES auth.users(id) not valid;

alter table "public"."receipts" validate constraint "fk_receipts_created_by";

alter table "public"."receipts" add constraint "fk_receipts_project" FOREIGN KEY (project_id) REFERENCES projects(id) not valid;

alter table "public"."receipts" validate constraint "fk_receipts_project";

create or replace view "public"."account_balances" as  SELECT a.id,
    a.account_number,
    a.account_name,
    a.account_type,
    a.ngo_area,
    a.currency_code,
    a.is_active,
    a.description,
    a.parent_account_id,
    a.tax_relevant,
    a.organization_id,
    a.created_at,
    a.updated_at,
    COALESCE(sum(
        CASE
            WHEN (r.debit_account_id = a.id) THEN r.base_amount
            WHEN (r.credit_account_id = a.id) THEN (- r.base_amount)
            ELSE (0)::numeric
        END), (0)::numeric) AS balance
   FROM (accounts a
     LEFT JOIN receipts r ON ((((r.debit_account_id = a.id) OR (r.credit_account_id = a.id)) AND (r.status = 'APPROVED'::text))))
  GROUP BY a.id;


create or replace view "public"."project_overview" as  SELECT p.id,
    p.project_code,
    p.name,
    p.description,
    p.status,
    p.start_date,
    p.end_date,
    p.budget_amount,
    p.currency_code AS budget_currency_code,
    p.spent_amount,
    p.country,
    p.region,
    p.coordinates,
    p.ngo_area,
    p.donor_information,
    p.reporting_required,
    p.next_report_due,
    p.organization_id,
    p.is_active,
    p.created_at,
    p.updated_at,
    p.total_budget,
    p.budget_currency,
    p.responsible_user_id,
    p.donor_name,
        CASE
            WHEN (p.total_budget > (0)::numeric) THEN round(((p.spent_amount / p.total_budget) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS budget_utilization_percent,
    (p.total_budget - p.spent_amount) AS remaining_budget,
    count(DISTINCT r.id) AS receipt_count
   FROM (projects p
     LEFT JOIN receipts r ON ((r.project_id = p.id)))
  GROUP BY p.id;


create or replace view "public"."project_statistics" as  SELECT p.id,
    p.name,
    p.project_code,
    p.budget_amount,
    p.spent_amount,
    (p.budget_amount - p.spent_amount) AS remaining_budget,
        CASE
            WHEN (p.budget_amount > (0)::numeric) THEN (((p.spent_amount / p.budget_amount) * (100)::numeric))::numeric(5,2)
            ELSE (0)::numeric
        END AS budget_utilization_percent,
    (p.spent_amount > p.budget_amount) AS is_over_budget,
        CASE
            WHEN (p.end_date IS NOT NULL) THEN (p.end_date - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_until_deadline,
    ( SELECT count(*) AS count
           FROM receipts r
          WHERE (r.project_id = p.id)) AS receipt_count,
    p.organization_id
   FROM projects p
  WHERE (p.is_active = true);


create policy "accounts_insert_policy"
on "public"."accounts"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text));


create policy "accounts_select_policy"
on "public"."accounts"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "accounts_update_policy"
on "public"."accounts"
as permissive
for update
to public
using ((auth.role() = 'authenticated'::text));


create policy "currencies_insert_policy"
on "public"."currencies"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text));


create policy "currencies_select_policy"
on "public"."currencies"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "currencies_update_policy"
on "public"."currencies"
as permissive
for update
to public
using ((auth.role() = 'authenticated'::text));


create policy "projects_insert_policy"
on "public"."projects"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text));


create policy "projects_select_policy"
on "public"."projects"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "projects_update_policy"
on "public"."projects"
as permissive
for update
to public
using ((auth.role() = 'authenticated'::text));


create policy "receipts_delete_policy"
on "public"."receipts"
as permissive
for delete
to public
using ((auth.role() = 'authenticated'::text));


create policy "receipts_insert_policy"
on "public"."receipts"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text));


create policy "receipts_select_policy"
on "public"."receipts"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "receipts_update_policy"
on "public"."receipts"
as permissive
for update
to public
using ((auth.role() = 'authenticated'::text));



