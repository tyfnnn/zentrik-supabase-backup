drop policy "Admins can create invites" on "public"."organization_invites";

drop policy "Admins can revoke invites" on "public"."organization_invites";

drop policy "Organization members can view invites" on "public"."organization_invites";

drop policy "Organizations are manageable by system admins" on "public"."organizations";

drop policy "Project managers can create projects" on "public"."projects";

drop policy "Users can update own projects or if authorized" on "public"."projects";

drop policy "projects_insert_policy" on "public"."projects";

drop policy "projects_select_policy" on "public"."projects";

drop policy "projects_update_policy" on "public"."projects";

revoke delete on table "public"."projects" from "anon";

revoke insert on table "public"."projects" from "anon";

revoke references on table "public"."projects" from "anon";

revoke select on table "public"."projects" from "anon";

revoke trigger on table "public"."projects" from "anon";

revoke truncate on table "public"."projects" from "anon";

revoke update on table "public"."projects" from "anon";

revoke delete on table "public"."receipts" from "anon";

revoke insert on table "public"."receipts" from "anon";

revoke references on table "public"."receipts" from "anon";

revoke select on table "public"."receipts" from "anon";

revoke trigger on table "public"."receipts" from "anon";

revoke truncate on table "public"."receipts" from "anon";

revoke update on table "public"."receipts" from "anon";

alter table "public"."users" disable row level security;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.log_project_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Log erstellen/bearbeiten/löschen von Projekten
    INSERT INTO audit_log (
        table_name, 
        record_id, 
        action, 
        user_id, 
        organization_id,
        timestamp
    ) VALUES (
        'projects',
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        auth.uid(),
        COALESCE(NEW.organization_id, OLD.organization_id),
        NOW()
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_organization_id()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    org_id uuid;
BEGIN
    -- Direkt aus users-Tabelle holen, ohne RLS-Checks
    SELECT organization_id INTO org_id
    FROM users 
    WHERE id = auth.uid();
    
    RETURN org_id;
END;
$function$
;

create policy "Accounts organization isolation"
on "public"."accounts"
as permissive
for select
to authenticated
using (((organization_id = get_user_organization_id()) OR (( SELECT users.role
   FROM users
  WHERE (users.id = auth.uid())) = 'SYSTEM_ADMIN'::text)));


create policy "Authenticated users can create invites"
on "public"."organization_invites"
as permissive
for insert
to authenticated
with check (true);


create policy "Authenticated users can update invites"
on "public"."organization_invites"
as permissive
for update
to authenticated
using (true)
with check (true);


create policy "Authenticated users can view invites"
on "public"."organization_invites"
as permissive
for select
to authenticated
using (true);


create policy "All authenticated users can view organizations"
on "public"."organizations"
as permissive
for select
to authenticated
using (true);


create policy "Authenticated users can create organizations"
on "public"."organizations"
as permissive
for insert
to authenticated
with check (true);


create policy "Users can only view memberships from their organization project"
on "public"."project_memberships"
as permissive
for select
to public
using ((project_id IN ( SELECT p.id
   FROM (projects p
     JOIN users u ON ((u.organization_id = p.organization_id)))
  WHERE (u.id = auth.uid()))));


create policy "simple_organization_isolation"
on "public"."projects"
as permissive
for all
to authenticated
using ((organization_id IN ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))));


create policy "Organization members can create receipts"
on "public"."receipts"
as permissive
for insert
to public
with check ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.organization_id = receipts.organization_id)))));


create policy "Receipts insert policy"
on "public"."receipts"
as permissive
for insert
to authenticated
with check ((organization_id = get_user_organization_id()));


create policy "Receipts organization isolation"
on "public"."receipts"
as permissive
for select
to authenticated
using (((organization_id = get_user_organization_id()) OR (( SELECT users.role
   FROM users
  WHERE (users.id = auth.uid())) = 'SYSTEM_ADMIN'::text)));


create policy "Users can only view receipts from their organization projects"
on "public"."receipts"
as permissive
for select
to public
using ((project_id IN ( SELECT p.id
   FROM (projects p
     JOIN users u ON ((u.organization_id = p.organization_id)))
  WHERE (u.id = auth.uid()))));


create policy "Authenticated users can view other users"
on "public"."users"
as permissive
for select
to authenticated
using (true);


create policy "System admins have full access"
on "public"."users"
as permissive
for all
to public
using ((EXISTS ( SELECT 1
   FROM (auth.users au
     JOIN users pu ON ((au.id = pu.id)))
  WHERE ((au.id = auth.uid()) AND (pu.role = 'SYSTEM_ADMIN'::text)))));


create policy "Users can update themselves"
on "public"."users"
as permissive
for update
to public
using ((id = auth.uid()))
with check ((id = auth.uid()));


create policy "Users can view themselves"
on "public"."users"
as permissive
for select
to public
using ((id = auth.uid()));



