create table "public"."accounts" (
    "id" uuid not null default gen_random_uuid(),
    "account_number" text not null,
    "account_name" text not null,
    "account_type" text not null,
    "ngo_area" text not null,
    "currency_code" text not null,
    "is_active" boolean default true,
    "description" text,
    "parent_account_id" uuid,
    "tax_relevant" boolean default false,
    "organization_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."accounts" enable row level security;

create table "public"."currencies" (
    "code" text not null,
    "name" text not null,
    "symbol" text not null,
    "decimal_places" integer default 2,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."currencies" enable row level security;

create table "public"."organizations" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "website" text,
    "logo_url" text,
    "settings" jsonb not null default '{"approvalLimits": {"MEMBER": "200", "SYSTEM_ADMIN": "999999", "FINANCE_ADMIN": "20000", "PROJECT_MANAGER": "2000"}, "defaultCurrency": "EUR", "allowSelfApproval": false, "requireDualApprovalAbove": "5000", "autoApproveRecurringExpenses": false, "projectBudgetRequiresApproval": true}'::jsonb,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."organizations" enable row level security;

create table "public"."project_memberships" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "project_id" uuid not null,
    "role" text not null default 'VIEWER'::text,
    "custom_approval_limit" numeric(15,2),
    "is_active" boolean default true,
    "assigned_at" timestamp with time zone default now(),
    "assigned_by" uuid
);


alter table "public"."project_memberships" enable row level security;

create table "public"."projects" (
    "id" uuid not null default gen_random_uuid(),
    "project_code" text not null,
    "name" text not null,
    "description" text,
    "status" text default 'PLANNING'::text,
    "start_date" date not null,
    "end_date" date,
    "budget_amount" numeric(15,2) not null,
    "budget_currency_code" text not null,
    "spent_amount" numeric(15,2) default 0,
    "country" text,
    "region" text,
    "coordinates" text,
    "ngo_area" text not null default 'IDEELL'::text,
    "donor_information" text,
    "reporting_required" boolean default false,
    "next_report_due" date,
    "organization_id" uuid not null,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."projects" enable row level security;

create table "public"."receipts" (
    "id" uuid not null default gen_random_uuid(),
    "receipt_number" text,
    "type" text not null,
    "status" text default 'DRAFT'::text,
    "receipt_date" date not null,
    "entry_date" date default CURRENT_DATE,
    "debit_account_id" uuid not null,
    "credit_account_id" uuid not null,
    "original_amount" numeric(15,2) not null,
    "original_currency_code" text not null,
    "exchange_rate" numeric(10,6),
    "base_amount" numeric(15,2) not null,
    "base_currency_code" text not null,
    "project_id" uuid,
    "description" text not null,
    "vendor" text,
    "reference" text,
    "notes" text,
    "tax_amount" numeric(15,2),
    "tax_rate" numeric(5,2),
    "is_deductible" boolean default false,
    "image_paths" jsonb default '[]'::jsonb,
    "ocr_text" text,
    "ocr_confidence" real,
    "approved_by" uuid,
    "approved_at" timestamp with time zone,
    "organization_id" uuid not null,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."receipts" enable row level security;

create table "public"."users" (
    "id" uuid not null,
    "email" text not null,
    "first_name" text not null,
    "last_name" text not null,
    "role" text not null default 'MEMBER'::text,
    "organization_id" uuid,
    "is_active" boolean default true,
    "avatar_url" text,
    "last_login_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX accounts_account_number_key ON public.accounts USING btree (account_number);

CREATE UNIQUE INDEX accounts_pkey ON public.accounts USING btree (id);

CREATE UNIQUE INDEX currencies_pkey ON public.currencies USING btree (code);

CREATE INDEX idx_accounts_ngo_area ON public.accounts USING btree (ngo_area);

CREATE INDEX idx_accounts_number ON public.accounts USING btree (account_number);

CREATE INDEX idx_accounts_organization ON public.accounts USING btree (organization_id);

CREATE INDEX idx_accounts_type ON public.accounts USING btree (account_type);

CREATE INDEX idx_project_memberships_project ON public.project_memberships USING btree (project_id);

CREATE INDEX idx_project_memberships_user ON public.project_memberships USING btree (user_id);

CREATE INDEX idx_projects_code ON public.projects USING btree (project_code);

CREATE INDEX idx_projects_end_date ON public.projects USING btree (end_date);

CREATE INDEX idx_projects_organization ON public.projects USING btree (organization_id);

CREATE INDEX idx_projects_start_date ON public.projects USING btree (start_date);

CREATE INDEX idx_projects_status ON public.projects USING btree (status);

CREATE INDEX idx_receipts_created_by ON public.receipts USING btree (created_by);

CREATE INDEX idx_receipts_credit_account ON public.receipts USING btree (credit_account_id);

CREATE INDEX idx_receipts_date ON public.receipts USING btree (receipt_date);

CREATE INDEX idx_receipts_debit_account ON public.receipts USING btree (debit_account_id);

CREATE INDEX idx_receipts_organization ON public.receipts USING btree (organization_id);

CREATE INDEX idx_receipts_project ON public.receipts USING btree (project_id);

CREATE INDEX idx_receipts_status ON public.receipts USING btree (status);

CREATE INDEX idx_receipts_type ON public.receipts USING btree (type);

CREATE INDEX idx_users_email ON public.users USING btree (email);

CREATE INDEX idx_users_organization ON public.users USING btree (organization_id);

CREATE INDEX idx_users_role ON public.users USING btree (role);

CREATE UNIQUE INDEX organizations_pkey ON public.organizations USING btree (id);

CREATE UNIQUE INDEX project_memberships_pkey ON public.project_memberships USING btree (id);

CREATE UNIQUE INDEX projects_pkey ON public.projects USING btree (id);

CREATE UNIQUE INDEX receipts_pkey ON public.receipts USING btree (id);

CREATE UNIQUE INDEX unique_project_code_per_org ON public.projects USING btree (project_code, organization_id);

CREATE UNIQUE INDEX unique_user_project ON public.project_memberships USING btree (user_id, project_id);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

alter table "public"."accounts" add constraint "accounts_pkey" PRIMARY KEY using index "accounts_pkey";

alter table "public"."currencies" add constraint "currencies_pkey" PRIMARY KEY using index "currencies_pkey";

alter table "public"."organizations" add constraint "organizations_pkey" PRIMARY KEY using index "organizations_pkey";

alter table "public"."project_memberships" add constraint "project_memberships_pkey" PRIMARY KEY using index "project_memberships_pkey";

alter table "public"."projects" add constraint "projects_pkey" PRIMARY KEY using index "projects_pkey";

alter table "public"."receipts" add constraint "receipts_pkey" PRIMARY KEY using index "receipts_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."accounts" add constraint "accounts_account_number_key" UNIQUE using index "accounts_account_number_key";

alter table "public"."accounts" add constraint "accounts_account_type_check" CHECK ((account_type = ANY (ARRAY['ASSET'::text, 'LIABILITY'::text, 'EXPENSE'::text, 'REVENUE'::text]))) not valid;

alter table "public"."accounts" validate constraint "accounts_account_type_check";

alter table "public"."accounts" add constraint "accounts_currency_code_fkey" FOREIGN KEY (currency_code) REFERENCES currencies(code) not valid;

alter table "public"."accounts" validate constraint "accounts_currency_code_fkey";

alter table "public"."accounts" add constraint "accounts_ngo_area_check" CHECK ((ngo_area = ANY (ARRAY['IDEELL'::text, 'ASSET_MANAGEMENT'::text, 'PURPOSE_OPERATION'::text, 'ECONOMIC_OPERATION'::text]))) not valid;

alter table "public"."accounts" validate constraint "accounts_ngo_area_check";

alter table "public"."accounts" add constraint "accounts_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE not valid;

alter table "public"."accounts" validate constraint "accounts_organization_id_fkey";

alter table "public"."accounts" add constraint "accounts_parent_account_id_fkey" FOREIGN KEY (parent_account_id) REFERENCES accounts(id) not valid;

alter table "public"."accounts" validate constraint "accounts_parent_account_id_fkey";

alter table "public"."project_memberships" add constraint "project_memberships_assigned_by_fkey" FOREIGN KEY (assigned_by) REFERENCES users(id) not valid;

alter table "public"."project_memberships" validate constraint "project_memberships_assigned_by_fkey";

alter table "public"."project_memberships" add constraint "project_memberships_project_id_fkey" FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE not valid;

alter table "public"."project_memberships" validate constraint "project_memberships_project_id_fkey";

alter table "public"."project_memberships" add constraint "project_memberships_role_check" CHECK ((role = ANY (ARRAY['VIEWER'::text, 'CONTRIBUTOR'::text, 'APPROVER'::text, 'MANAGER'::text]))) not valid;

alter table "public"."project_memberships" validate constraint "project_memberships_role_check";

alter table "public"."project_memberships" add constraint "project_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."project_memberships" validate constraint "project_memberships_user_id_fkey";

alter table "public"."project_memberships" add constraint "unique_user_project" UNIQUE using index "unique_user_project";

alter table "public"."projects" add constraint "projects_budget_currency_code_fkey" FOREIGN KEY (budget_currency_code) REFERENCES currencies(code) not valid;

alter table "public"."projects" validate constraint "projects_budget_currency_code_fkey";

alter table "public"."projects" add constraint "projects_ngo_area_check" CHECK ((ngo_area = ANY (ARRAY['IDEELL'::text, 'ASSET_MANAGEMENT'::text, 'PURPOSE_OPERATION'::text, 'ECONOMIC_OPERATION'::text]))) not valid;

alter table "public"."projects" validate constraint "projects_ngo_area_check";

alter table "public"."projects" add constraint "projects_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE not valid;

alter table "public"."projects" validate constraint "projects_organization_id_fkey";

alter table "public"."projects" add constraint "projects_status_check" CHECK ((status = ANY (ARRAY['PLANNING'::text, 'APPROVED'::text, 'ACTIVE'::text, 'PAUSED'::text, 'COMPLETED'::text, 'CANCELLED'::text]))) not valid;

alter table "public"."projects" validate constraint "projects_status_check";

alter table "public"."projects" add constraint "unique_project_code_per_org" UNIQUE using index "unique_project_code_per_org";

alter table "public"."projects" add constraint "valid_budget" CHECK ((budget_amount > (0)::numeric)) not valid;

alter table "public"."projects" validate constraint "valid_budget";

alter table "public"."projects" add constraint "valid_dates" CHECK (((end_date IS NULL) OR (end_date >= start_date))) not valid;

alter table "public"."projects" validate constraint "valid_dates";

alter table "public"."projects" add constraint "valid_spent" CHECK ((spent_amount >= (0)::numeric)) not valid;

alter table "public"."projects" validate constraint "valid_spent";

alter table "public"."receipts" add constraint "different_accounts" CHECK ((debit_account_id <> credit_account_id)) not valid;

alter table "public"."receipts" validate constraint "different_accounts";

alter table "public"."receipts" add constraint "receipts_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES users(id) not valid;

alter table "public"."receipts" validate constraint "receipts_approved_by_fkey";

alter table "public"."receipts" add constraint "receipts_base_currency_code_fkey" FOREIGN KEY (base_currency_code) REFERENCES currencies(code) not valid;

alter table "public"."receipts" validate constraint "receipts_base_currency_code_fkey";

alter table "public"."receipts" add constraint "receipts_created_by_fkey" FOREIGN KEY (created_by) REFERENCES users(id) not valid;

alter table "public"."receipts" validate constraint "receipts_created_by_fkey";

alter table "public"."receipts" add constraint "receipts_credit_account_id_fkey" FOREIGN KEY (credit_account_id) REFERENCES accounts(id) not valid;

alter table "public"."receipts" validate constraint "receipts_credit_account_id_fkey";

alter table "public"."receipts" add constraint "receipts_debit_account_id_fkey" FOREIGN KEY (debit_account_id) REFERENCES accounts(id) not valid;

alter table "public"."receipts" validate constraint "receipts_debit_account_id_fkey";

alter table "public"."receipts" add constraint "receipts_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE not valid;

alter table "public"."receipts" validate constraint "receipts_organization_id_fkey";

alter table "public"."receipts" add constraint "receipts_original_currency_code_fkey" FOREIGN KEY (original_currency_code) REFERENCES currencies(code) not valid;

alter table "public"."receipts" validate constraint "receipts_original_currency_code_fkey";

alter table "public"."receipts" add constraint "receipts_project_id_fkey" FOREIGN KEY (project_id) REFERENCES projects(id) not valid;

alter table "public"."receipts" validate constraint "receipts_project_id_fkey";

alter table "public"."receipts" add constraint "receipts_status_check" CHECK ((status = ANY (ARRAY['DRAFT'::text, 'PENDING_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'BOOKED'::text]))) not valid;

alter table "public"."receipts" validate constraint "receipts_status_check";

alter table "public"."receipts" add constraint "receipts_type_check" CHECK ((type = ANY (ARRAY['EXPENSE'::text, 'INCOME'::text, 'TRANSFER'::text, 'OPENING_BALANCE'::text, 'CLOSING_ENTRY'::text]))) not valid;

alter table "public"."receipts" validate constraint "receipts_type_check";

alter table "public"."receipts" add constraint "valid_amounts" CHECK (((original_amount > (0)::numeric) AND (base_amount > (0)::numeric))) not valid;

alter table "public"."receipts" validate constraint "valid_amounts";

alter table "public"."receipts" add constraint "valid_ocr_confidence" CHECK (((ocr_confidence IS NULL) OR ((ocr_confidence >= (0)::double precision) AND (ocr_confidence <= (1)::double precision)))) not valid;

alter table "public"."receipts" validate constraint "valid_ocr_confidence";

alter table "public"."receipts" add constraint "valid_tax_rate" CHECK (((tax_rate IS NULL) OR ((tax_rate >= (0)::numeric) AND (tax_rate <= (100)::numeric)))) not valid;

alter table "public"."receipts" validate constraint "valid_tax_rate";

alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_id_fkey";

alter table "public"."users" add constraint "users_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_organization_id_fkey";

alter table "public"."users" add constraint "users_role_check" CHECK ((role = ANY (ARRAY['MEMBER'::text, 'PROJECT_MANAGER'::text, 'FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text]))) not valid;

alter table "public"."users" validate constraint "users_role_check";

alter table "public"."users" add constraint "valid_email" CHECK ((email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)) not valid;

alter table "public"."users" validate constraint "valid_email";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.assign_user_to_organization(user_id uuid, org_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    UPDATE users 
    SET organization_id = org_id 
    WHERE id = user_id AND organization_id IS NULL;
    
    RETURN FOUND;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_approve_receipt(receipt_id uuid, approver_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    receipt_record receipts%ROWTYPE;
    user_record users%ROWTYPE;
    org_settings JSONB;
    user_limit DECIMAL;
BEGIN
    -- Get receipt
    SELECT * INTO receipt_record FROM receipts WHERE id = receipt_id;
    IF NOT FOUND THEN RETURN FALSE; END IF;
    
    -- Get user
    SELECT * INTO user_record FROM users WHERE id = approver_user_id;
    IF NOT FOUND THEN RETURN FALSE; END IF;
    
    -- Check same organization
    IF receipt_record.organization_id != user_record.organization_id THEN
        RETURN FALSE;
    END IF;
    
    -- Get organization settings
    SELECT settings INTO org_settings 
    FROM organizations 
    WHERE id = user_record.organization_id;
    
    -- Get user approval limit
    user_limit := (org_settings->'approvalLimits'->user_record.role)::TEXT::DECIMAL;
    
    -- Check amount limit
    IF receipt_record.base_amount > user_limit THEN
        RETURN FALSE;
    END IF;
    
    -- Check self-approval
    IF receipt_record.created_by = approver_user_id 
       AND NOT (org_settings->>'allowSelfApproval')::BOOLEAN THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_organization_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  SELECT organization_id FROM users WHERE id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    default_org_id UUID;
BEGIN
    SELECT id INTO default_org_id 
    FROM organizations 
    WHERE name = 'Default NGO' 
    LIMIT 1;
    
    IF default_org_id IS NULL THEN
        INSERT INTO organizations (name, description)
        VALUES ('Default NGO', 'Automatisch erstellte Standard-Organisation')
        RETURNING id INTO default_org_id;
    END IF;

    INSERT INTO public.users (id, email, first_name, last_name, role, organization_id, is_active)
    VALUES (
        NEW.id, 
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Unbekannt'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Unbekannt'),
        'MEMBER',
        default_org_id,
        true
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$function$
;

create or replace view "public"."monthly_receipt_stats" as  SELECT receipts.organization_id,
    receipts.project_id,
    date_trunc('month'::text, (receipts.receipt_date)::timestamp with time zone) AS month,
    count(*) AS receipt_count,
    sum(receipts.base_amount) AS total_amount,
    avg(receipts.base_amount) AS average_amount,
    receipts.type
   FROM receipts
  WHERE (receipts.status = 'BOOKED'::text)
  GROUP BY receipts.organization_id, receipts.project_id, (date_trunc('month'::text, (receipts.receipt_date)::timestamp with time zone)), receipts.type;


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


CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

create or replace view "public"."user_profile_status" as  SELECT au.id,
    au.email,
    au.created_at AS auth_created_at,
    u.id AS profile_id,
    u.first_name,
    u.last_name,
    u.organization_id,
        CASE
            WHEN (u.id IS NULL) THEN 'MISSING_PROFILE'::text
            ELSE 'PROFILE_EXISTS'::text
        END AS status
   FROM (auth.users au
     LEFT JOIN users u ON ((au.id = u.id)))
  ORDER BY au.created_at DESC;


grant delete on table "public"."accounts" to "anon";

grant insert on table "public"."accounts" to "anon";

grant references on table "public"."accounts" to "anon";

grant select on table "public"."accounts" to "anon";

grant trigger on table "public"."accounts" to "anon";

grant truncate on table "public"."accounts" to "anon";

grant update on table "public"."accounts" to "anon";

grant delete on table "public"."accounts" to "authenticated";

grant insert on table "public"."accounts" to "authenticated";

grant references on table "public"."accounts" to "authenticated";

grant select on table "public"."accounts" to "authenticated";

grant trigger on table "public"."accounts" to "authenticated";

grant truncate on table "public"."accounts" to "authenticated";

grant update on table "public"."accounts" to "authenticated";

grant delete on table "public"."accounts" to "service_role";

grant insert on table "public"."accounts" to "service_role";

grant references on table "public"."accounts" to "service_role";

grant select on table "public"."accounts" to "service_role";

grant trigger on table "public"."accounts" to "service_role";

grant truncate on table "public"."accounts" to "service_role";

grant update on table "public"."accounts" to "service_role";

grant delete on table "public"."currencies" to "anon";

grant insert on table "public"."currencies" to "anon";

grant references on table "public"."currencies" to "anon";

grant select on table "public"."currencies" to "anon";

grant trigger on table "public"."currencies" to "anon";

grant truncate on table "public"."currencies" to "anon";

grant update on table "public"."currencies" to "anon";

grant delete on table "public"."currencies" to "authenticated";

grant insert on table "public"."currencies" to "authenticated";

grant references on table "public"."currencies" to "authenticated";

grant select on table "public"."currencies" to "authenticated";

grant trigger on table "public"."currencies" to "authenticated";

grant truncate on table "public"."currencies" to "authenticated";

grant update on table "public"."currencies" to "authenticated";

grant delete on table "public"."currencies" to "service_role";

grant insert on table "public"."currencies" to "service_role";

grant references on table "public"."currencies" to "service_role";

grant select on table "public"."currencies" to "service_role";

grant trigger on table "public"."currencies" to "service_role";

grant truncate on table "public"."currencies" to "service_role";

grant update on table "public"."currencies" to "service_role";

grant delete on table "public"."organizations" to "anon";

grant insert on table "public"."organizations" to "anon";

grant references on table "public"."organizations" to "anon";

grant select on table "public"."organizations" to "anon";

grant trigger on table "public"."organizations" to "anon";

grant truncate on table "public"."organizations" to "anon";

grant update on table "public"."organizations" to "anon";

grant delete on table "public"."organizations" to "authenticated";

grant insert on table "public"."organizations" to "authenticated";

grant references on table "public"."organizations" to "authenticated";

grant select on table "public"."organizations" to "authenticated";

grant trigger on table "public"."organizations" to "authenticated";

grant truncate on table "public"."organizations" to "authenticated";

grant update on table "public"."organizations" to "authenticated";

grant delete on table "public"."organizations" to "service_role";

grant insert on table "public"."organizations" to "service_role";

grant references on table "public"."organizations" to "service_role";

grant select on table "public"."organizations" to "service_role";

grant trigger on table "public"."organizations" to "service_role";

grant truncate on table "public"."organizations" to "service_role";

grant update on table "public"."organizations" to "service_role";

grant delete on table "public"."project_memberships" to "anon";

grant insert on table "public"."project_memberships" to "anon";

grant references on table "public"."project_memberships" to "anon";

grant select on table "public"."project_memberships" to "anon";

grant trigger on table "public"."project_memberships" to "anon";

grant truncate on table "public"."project_memberships" to "anon";

grant update on table "public"."project_memberships" to "anon";

grant delete on table "public"."project_memberships" to "authenticated";

grant insert on table "public"."project_memberships" to "authenticated";

grant references on table "public"."project_memberships" to "authenticated";

grant select on table "public"."project_memberships" to "authenticated";

grant trigger on table "public"."project_memberships" to "authenticated";

grant truncate on table "public"."project_memberships" to "authenticated";

grant update on table "public"."project_memberships" to "authenticated";

grant delete on table "public"."project_memberships" to "service_role";

grant insert on table "public"."project_memberships" to "service_role";

grant references on table "public"."project_memberships" to "service_role";

grant select on table "public"."project_memberships" to "service_role";

grant trigger on table "public"."project_memberships" to "service_role";

grant truncate on table "public"."project_memberships" to "service_role";

grant update on table "public"."project_memberships" to "service_role";

grant delete on table "public"."projects" to "anon";

grant insert on table "public"."projects" to "anon";

grant references on table "public"."projects" to "anon";

grant select on table "public"."projects" to "anon";

grant trigger on table "public"."projects" to "anon";

grant truncate on table "public"."projects" to "anon";

grant update on table "public"."projects" to "anon";

grant delete on table "public"."projects" to "authenticated";

grant insert on table "public"."projects" to "authenticated";

grant references on table "public"."projects" to "authenticated";

grant select on table "public"."projects" to "authenticated";

grant trigger on table "public"."projects" to "authenticated";

grant truncate on table "public"."projects" to "authenticated";

grant update on table "public"."projects" to "authenticated";

grant delete on table "public"."projects" to "service_role";

grant insert on table "public"."projects" to "service_role";

grant references on table "public"."projects" to "service_role";

grant select on table "public"."projects" to "service_role";

grant trigger on table "public"."projects" to "service_role";

grant truncate on table "public"."projects" to "service_role";

grant update on table "public"."projects" to "service_role";

grant delete on table "public"."receipts" to "anon";

grant insert on table "public"."receipts" to "anon";

grant references on table "public"."receipts" to "anon";

grant select on table "public"."receipts" to "anon";

grant trigger on table "public"."receipts" to "anon";

grant truncate on table "public"."receipts" to "anon";

grant update on table "public"."receipts" to "anon";

grant delete on table "public"."receipts" to "authenticated";

grant insert on table "public"."receipts" to "authenticated";

grant references on table "public"."receipts" to "authenticated";

grant select on table "public"."receipts" to "authenticated";

grant trigger on table "public"."receipts" to "authenticated";

grant truncate on table "public"."receipts" to "authenticated";

grant update on table "public"."receipts" to "authenticated";

grant delete on table "public"."receipts" to "service_role";

grant insert on table "public"."receipts" to "service_role";

grant references on table "public"."receipts" to "service_role";

grant select on table "public"."receipts" to "service_role";

grant trigger on table "public"."receipts" to "service_role";

grant truncate on table "public"."receipts" to "service_role";

grant update on table "public"."receipts" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";

create policy "Users can view organization accounts"
on "public"."accounts"
as permissive
for select
to public
using ((organization_id = get_user_organization_id()));


create policy "Authenticated users can view currencies"
on "public"."currencies"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "System admins can manage currencies"
on "public"."currencies"
as permissive
for all
to public
using ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = 'SYSTEM_ADMIN'::text)))));


create policy "Users can view own organization"
on "public"."organizations"
as permissive
for select
to public
using ((id = get_user_organization_id()));


create policy "Users can view own project memberships"
on "public"."project_memberships"
as permissive
for select
to public
using (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['PROJECT_MANAGER'::text, 'FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text])) AND (users.organization_id = ( SELECT u2.organization_id
           FROM users u2
          WHERE (u2.id = project_memberships.user_id))))))));


create policy "Project managers can create projects"
on "public"."projects"
as permissive
for insert
to public
with check (((organization_id = ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['PROJECT_MANAGER'::text, 'FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text])))))));


create policy "Users can update own projects or if authorized"
on "public"."projects"
as permissive
for update
to public
using (((organization_id = ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) AND ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['PROJECT_MANAGER'::text, 'FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text]))))) OR (EXISTS ( SELECT 1
   FROM project_memberships
  WHERE ((project_memberships.project_id = projects.id) AND (project_memberships.user_id = auth.uid()) AND (project_memberships.role = ANY (ARRAY['MANAGER'::text, 'APPROVER'::text])) AND (project_memberships.is_active = true)))))));


create policy "Users can create receipts"
on "public"."receipts"
as permissive
for insert
to public
with check (((organization_id = ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) AND (created_by = auth.uid())));


create policy "Users can update own draft receipts"
on "public"."receipts"
as permissive
for update
to public
using (((organization_id = ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) AND (((created_by = auth.uid()) AND (status = ANY (ARRAY['DRAFT'::text, 'REJECTED'::text]))) OR (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = ANY (ARRAY['FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text]))))))));


create policy "Users can view organization receipts"
on "public"."receipts"
as permissive
for select
to public
using ((organization_id = ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))));


create policy "Allow user registration without org"
on "public"."users"
as permissive
for insert
to public
with check (((id = auth.uid()) AND (organization_id IS NULL)));


create policy "Enable INSERT for authenticated users during signup"
on "public"."users"
as permissive
for insert
to public
with check ((auth.uid() = id));


create policy "Enable user profile creation during signup"
on "public"."users"
as permissive
for insert
to public
with check ((id = auth.uid()));


create policy "Service role bypass"
on "public"."users"
as permissive
for all
to service_role
using (true);


create policy "Service role can manage users"
on "public"."users"
as permissive
for all
to public
using (((auth.jwt() ->> 'role'::text) = 'service_role'::text));


create policy "Users can insert own profile"
on "public"."users"
as permissive
for insert
to public
with check (((id = auth.uid()) AND (organization_id = ( SELECT users_1.organization_id
   FROM users users_1
  WHERE (users_1.id = auth.uid())))));


create policy "user_select_own"
on "public"."users"
as permissive
for select
to public
using ((id = auth.uid()));


create policy "user_update_own"
on "public"."users"
as permissive
for update
to public
using ((id = auth.uid()));


CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_currencies_updated_at BEFORE UPDATE ON public.currencies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON public.receipts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


