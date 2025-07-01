alter table "public"."projects" drop constraint "projects_currency_code_fkey";

drop view if exists "public"."project_overview";

drop view if exists "public"."project_statistics";

alter table "public"."projects" drop column "currency_code";

alter table "public"."projects" add column "budget_currency_code" text not null;

alter table "public"."projects" add constraint "projects_budget_currency_code_fkey" FOREIGN KEY (budget_currency_code) REFERENCES currencies(code) not valid;

alter table "public"."projects" validate constraint "projects_budget_currency_code_fkey";

create or replace view "public"."project_overview" as  SELECT p.id,
    p.project_code,
    p.name,
    p.description,
    p.status,
    p.start_date,
    p.end_date,
    p.budget_amount,
    p.budget_currency_code,
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



