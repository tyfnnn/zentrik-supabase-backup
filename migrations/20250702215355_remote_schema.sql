create type "public"."user_role" as enum ('MEMBER', 'PROJECT_MANAGER', 'FINANCE_ADMIN', 'SYSTEM_ADMIN');

create table "public"."organization_invites" (
    "code" text not null,
    "organization_id" uuid not null,
    "role" user_role not null default 'MEMBER'::user_role,
    "max_uses" integer not null default 1,
    "used_count" integer not null default 0,
    "status" text not null default 'pending'::text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone default now(),
    "expires_at" timestamp with time zone default (now() + '7 days'::interval)
);


alter table "public"."organization_invites" enable row level security;

alter table "public"."users" add column "invited_by" uuid;

alter table "public"."users" add column "joined_via_code" text;

CREATE INDEX idx_invites_code ON public.organization_invites USING btree (code);

CREATE INDEX idx_invites_expires ON public.organization_invites USING btree (expires_at) WHERE (status = 'pending'::text);

CREATE INDEX idx_invites_organization ON public.organization_invites USING btree (organization_id);

CREATE INDEX idx_invites_status ON public.organization_invites USING btree (status) WHERE (status = 'pending'::text);

CREATE INDEX idx_organizations_name ON public.organizations USING btree (name);

CREATE UNIQUE INDEX organization_invites_pkey ON public.organization_invites USING btree (code);

alter table "public"."organization_invites" add constraint "organization_invites_pkey" PRIMARY KEY using index "organization_invites_pkey";

alter table "public"."organization_invites" add constraint "check_max_uses" CHECK ((max_uses > 0)) not valid;

alter table "public"."organization_invites" validate constraint "check_max_uses";

alter table "public"."organization_invites" add constraint "check_status" CHECK ((status = ANY (ARRAY['pending'::text, 'used'::text, 'expired'::text, 'revoked'::text]))) not valid;

alter table "public"."organization_invites" validate constraint "check_status";

alter table "public"."organization_invites" add constraint "check_used_count" CHECK (((used_count >= 0) AND (used_count <= max_uses))) not valid;

alter table "public"."organization_invites" validate constraint "check_used_count";

alter table "public"."organization_invites" add constraint "organization_invites_created_by_fkey" FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."organization_invites" validate constraint "organization_invites_created_by_fkey";

alter table "public"."organization_invites" add constraint "organization_invites_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE not valid;

alter table "public"."organization_invites" validate constraint "organization_invites_organization_id_fkey";

alter table "public"."users" add constraint "fk_users_organization" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL not valid;

alter table "public"."users" validate constraint "fk_users_organization";

alter table "public"."users" add constraint "users_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES users(id) not valid;

alter table "public"."users" validate constraint "users_invited_by_fkey";

set check_function_bodies = off;

create or replace view "public"."active_invites_view" as  SELECT i.code,
    i.organization_id,
    i.role,
    i.max_uses,
    i.used_count,
    i.status,
    i.created_by,
    i.created_at,
    i.expires_at,
    o.name AS organization_name,
    u.email AS created_by_email,
    ((u.first_name || ' '::text) || u.last_name) AS created_by_name,
    (i.expires_at - now()) AS time_remaining,
    (i.max_uses - i.used_count) AS uses_remaining
   FROM ((organization_invites i
     JOIN organizations o ON ((i.organization_id = o.id)))
     JOIN users u ON ((i.created_by = u.id)))
  WHERE ((i.status = 'pending'::text) AND (i.expires_at > now()));


CREATE OR REPLACE FUNCTION public.expire_old_invites()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE organization_invites 
    SET status = 'expired'
    WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_invite_code()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generiere einen Code im Format XXX-XXX-XXX
        code := UPPER(
            substr(md5(random()::text), 1, 3) || '-' ||
            substr(md5(random()::text), 1, 3) || '-' ||
            substr(md5(random()::text), 1, 3)
        );
        
        -- Prüfe ob Code bereits existiert
        SELECT EXISTS(SELECT 1 FROM organization_invites WHERE organization_invites.code = code) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN code;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_invite_code()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.code IS NULL OR NEW.code = '' THEN
        NEW.code := generate_invite_code();
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.use_invite_code(p_code text, p_user_id uuid)
 RETURNS TABLE(success boolean, message text, organization_id uuid, role user_role)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_invite RECORD;
BEGIN
    -- Hole die Einladung
    SELECT * INTO v_invite 
    FROM organization_invites 
    WHERE code = p_code 
    FOR UPDATE;
    
    -- Prüfe ob Einladung existiert
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Ungültiger Einladungscode'::TEXT, NULL::UUID, NULL::user_role;
        RETURN;
    END IF;
    
    -- Prüfe Status
    IF v_invite.status != 'pending' THEN
        RETURN QUERY SELECT FALSE, 'Einladungscode wurde bereits verwendet oder ist abgelaufen'::TEXT, NULL::UUID, NULL::user_role;
        RETURN;
    END IF;
    
    -- Prüfe Ablaufdatum
    IF v_invite.expires_at < NOW() THEN
        UPDATE organization_invites SET status = 'expired' WHERE code = p_code;
        RETURN QUERY SELECT FALSE, 'Einladungscode ist abgelaufen'::TEXT, NULL::UUID, NULL::user_role;
        RETURN;
    END IF;
    
    -- Prüfe Verwendungslimit
    IF v_invite.used_count >= v_invite.max_uses THEN
        UPDATE organization_invites SET status = 'used' WHERE code = p_code;
        RETURN QUERY SELECT FALSE, 'Einladungscode wurde bereits zu oft verwendet'::TEXT, NULL::UUID, NULL::user_role;
        RETURN;
    END IF;
    
    -- Aktualisiere Einladung
    UPDATE organization_invites 
    SET used_count = used_count + 1,
        status = CASE 
            WHEN used_count + 1 >= max_uses THEN 'used'
            ELSE 'pending'
        END
    WHERE code = p_code;
    
    -- Aktualisiere User
    UPDATE users 
    SET organization_id = v_invite.organization_id,
        role = v_invite.role,
        joined_via_code = p_code,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    RETURN QUERY SELECT TRUE, 'Erfolgreich der Organisation beigetreten'::TEXT, v_invite.organization_id, v_invite.role;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."organization_invites" to "anon";

grant insert on table "public"."organization_invites" to "anon";

grant references on table "public"."organization_invites" to "anon";

grant select on table "public"."organization_invites" to "anon";

grant trigger on table "public"."organization_invites" to "anon";

grant truncate on table "public"."organization_invites" to "anon";

grant update on table "public"."organization_invites" to "anon";

grant delete on table "public"."organization_invites" to "authenticated";

grant insert on table "public"."organization_invites" to "authenticated";

grant references on table "public"."organization_invites" to "authenticated";

grant select on table "public"."organization_invites" to "authenticated";

grant trigger on table "public"."organization_invites" to "authenticated";

grant truncate on table "public"."organization_invites" to "authenticated";

grant update on table "public"."organization_invites" to "authenticated";

grant delete on table "public"."organization_invites" to "service_role";

grant insert on table "public"."organization_invites" to "service_role";

grant references on table "public"."organization_invites" to "service_role";

grant select on table "public"."organization_invites" to "service_role";

grant trigger on table "public"."organization_invites" to "service_role";

grant truncate on table "public"."organization_invites" to "service_role";

grant update on table "public"."organization_invites" to "service_role";

create policy "Admins can create invites"
on "public"."organization_invites"
as permissive
for insert
to public
with check ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.organization_id = organization_invites.organization_id) AND (users.role = ANY (ARRAY['PROJECT_MANAGER'::text, 'FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text]))))));


create policy "Admins can revoke invites"
on "public"."organization_invites"
as permissive
for update
to public
using ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.organization_id = organization_invites.organization_id) AND (users.role = ANY (ARRAY['FINANCE_ADMIN'::text, 'SYSTEM_ADMIN'::text]))))))
with check ((status = 'revoked'::text));


create policy "Organization members can view invites"
on "public"."organization_invites"
as permissive
for select
to public
using ((organization_id IN ( SELECT users.organization_id
   FROM users
  WHERE (users.id = auth.uid()))));


create policy "Organizations are manageable by system admins"
on "public"."organizations"
as permissive
for all
to public
using ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = 'SYSTEM_ADMIN'::text)))));


create policy "Organizations are viewable by authenticated users"
on "public"."organizations"
as permissive
for select
to public
using ((auth.role() = 'authenticated'::text));


create policy "Temporary: Allow all authenticated users to create organization"
on "public"."organizations"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text));


CREATE TRIGGER trigger_set_invite_code BEFORE INSERT ON public.organization_invites FOR EACH ROW EXECUTE FUNCTION set_invite_code();


