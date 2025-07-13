alter table "public"."accounts" drop constraint "accounts_ngo_area_check";

alter table "public"."projects" drop constraint "projects_ngo_area_check";

alter table "public"."accounts" drop constraint "check_ngo_area";

alter table "public"."projects" add constraint "check_projects_ngo_area" CHECK ((ngo_area = ANY (ARRAY['ideell'::text, 'asset_management'::text, 'purpose_operation'::text, 'economic_operation'::text]))) not valid;

alter table "public"."projects" validate constraint "check_projects_ngo_area";

alter table "public"."accounts" add constraint "check_ngo_area" CHECK ((ngo_area = ANY (ARRAY['ideell'::text, 'asset_management'::text, 'purpose_operation'::text, 'economic_operation'::text]))) not valid;

alter table "public"."accounts" validate constraint "check_ngo_area";

create policy "Users can create accounts for their organization"
on "public"."accounts"
as permissive
for insert
to public
with check (((organization_id IN ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) OR (organization_id IS NULL)));


create policy "Users can update accounts of their organization"
on "public"."accounts"
as permissive
for update
to public
using ((organization_id IN ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))));


create policy "Users can view accounts of their organization"
on "public"."accounts"
as permissive
for select
to public
using (((organization_id IN ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))) OR (organization_id IS NULL)));



