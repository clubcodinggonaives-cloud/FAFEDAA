-- Lot 2: internal staff authorization. Public access stays closed.
-- Apply only after Lot 1 has been operationally validated in an isolated project.

create or replace function public.is_active_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.is_active
  );
$$;

create or replace function public.has_any_role(_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_staff() and exists (
    select 1
    from public.profile_roles pr
    join public.roles r on r.id = pr.role_id
    where pr.profile_id = (select auth.uid())
      and r.name = any(coalesce(_roles, array[]::text[]))
  );
$$;

create or replace function public.can_access_assistance_request(_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_staff() and (
    public.has_any_role(array['super_admin', 'admin']::text[])
    or exists (
      select 1 from public.case_assignments ca
      where ca.assistance_request_id = _request_id
        and ca.assignee_id = (select auth.uid())
        and ca.ended_at is null
    )
  );
$$;

create or replace function public.can_access_beneficiary(_beneficiary_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_staff() and (
    public.has_any_role(array['super_admin', 'admin']::text[])
    or exists (
      select 1
      from public.assistance_requests ar
      join public.case_assignments ca on ca.assistance_request_id = ar.id
      where ar.beneficiary_id = _beneficiary_id
        and ca.assignee_id = (select auth.uid())
        and ca.ended_at is null
    )
  );
$$;

create or replace function public.provision_invited_staff(
  _actor_id uuid,
  _user_id uuid,
  _display_name text,
  _preferred_language text,
  _role_id smallint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_is_super_admin boolean;
  actor_is_admin boolean;
  requested_role text;
begin
  select exists (
    select 1 from public.profiles p
    join public.profile_roles pr on pr.profile_id = p.id
    join public.roles r on r.id = pr.role_id
    where p.id = _actor_id and p.is_active and r.name = 'super_admin'
  ) into actor_is_super_admin;
  select exists (
    select 1 from public.profiles p
    join public.profile_roles pr on pr.profile_id = p.id
    join public.roles r on r.id = pr.role_id
    where p.id = _actor_id and p.is_active and r.name = 'admin'
  ) into actor_is_admin;
  select r.name into requested_role from public.roles r where r.id = _role_id;

  if not (actor_is_super_admin or actor_is_admin)
     or requested_role is null
     or requested_role = 'super_admin'
     or (not actor_is_super_admin and requested_role not in ('program_manager', 'social_worker', 'content_editor')) then
    raise exception 'not authorized to provision this staff role' using errcode = '42501';
  end if;
  if _display_name is null or length(trim(_display_name)) not between 1 and 100
     or _preferred_language is null or _preferred_language not in ('fr', 'ht', 'en') then
    raise exception 'invalid staff profile' using errcode = '22023';
  end if;
  if not exists (select 1 from auth.users u where u.id = _user_id) then
    raise exception 'invited auth user does not exist' using errcode = '23503';
  end if;

  insert into public.profiles (id, display_name, preferred_language, is_active)
  values (_user_id, trim(_display_name), _preferred_language, true);
  insert into public.profile_roles (profile_id, role_id, assigned_by)
  values (_user_id, _role_id, _actor_id);
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
  values (_actor_id, 'staff.invited', 'profile', _user_id, jsonb_build_object('assigned_role', requested_role));
end;
$$;

create or replace function public.change_staff_role(
  _actor_id uuid,
  _target_profile_id uuid,
  _role_id smallint,
  _action text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_is_super_admin boolean;
  actor_is_admin boolean;
  requested_role text;
  did_change boolean := false;
begin
  select exists (
    select 1 from public.profiles p
    join public.profile_roles pr on pr.profile_id = p.id
    join public.roles r on r.id = pr.role_id
    where p.id = _actor_id and p.is_active and r.name = 'super_admin'
  ) into actor_is_super_admin;
  select exists (
    select 1 from public.profiles p
    join public.profile_roles pr on pr.profile_id = p.id
    join public.roles r on r.id = pr.role_id
    where p.id = _actor_id and p.is_active and r.name = 'admin'
  ) into actor_is_admin;
  select r.name into requested_role from public.roles r where r.id = _role_id;

  if _actor_id = _target_profile_id or not exists (
       select 1 from public.profiles p where p.id = _target_profile_id
     ) or not (actor_is_super_admin or actor_is_admin)
     or requested_role is null
     or requested_role = 'super_admin'
     or (not actor_is_super_admin and requested_role not in ('program_manager', 'social_worker', 'content_editor')) then
    raise exception 'not authorized to change this staff role' using errcode = '42501';
  end if;

  if _action = 'grant' then
    insert into public.profile_roles (profile_id, role_id, assigned_by)
    values (_target_profile_id, _role_id, _actor_id)
    on conflict (profile_id, role_id) do nothing;
    did_change := found;
  elsif _action = 'revoke' then
    delete from public.profile_roles pr
    where pr.profile_id = _target_profile_id and pr.role_id = _role_id;
    did_change := found;
  else
    raise exception 'invalid role action' using errcode = '22023';
  end if;

  if did_change then
    insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    values (_actor_id, 'staff.role_' || _action, 'profile', _target_profile_id,
      jsonb_build_object('role', requested_role));
  end if;
  return did_change;
end;
$$;

revoke all privileges on function public.is_active_staff() from public, anon, authenticated;
revoke all privileges on function public.has_any_role(text[]) from public, anon, authenticated;
revoke all privileges on function public.can_access_assistance_request(uuid) from public, anon, authenticated;
revoke all privileges on function public.can_access_beneficiary(uuid) from public, anon, authenticated;
revoke all privileges on function public.provision_invited_staff(uuid, uuid, text, text, smallint) from public, anon, authenticated, service_role;
revoke all privileges on function public.change_staff_role(uuid, uuid, smallint, text) from public, anon, authenticated, service_role;
grant execute on function public.is_active_staff() to authenticated;
grant execute on function public.has_any_role(text[]) to authenticated;
grant execute on function public.can_access_assistance_request(uuid) to authenticated;
grant execute on function public.can_access_beneficiary(uuid) to authenticated;
grant execute on function public.provision_invited_staff(uuid, uuid, text, text, smallint) to service_role;
grant execute on function public.change_staff_role(uuid, uuid, smallint, text) to service_role;

grant usage on schema public to authenticated;

-- Access is granted to authenticated users at the SQL layer; RLS below remains
-- the row-level boundary. No DELETE privilege is granted on protected records.
grant select, update (display_name, preferred_language) on public.profiles to authenticated;
grant select on public.roles, public.profile_roles, public.audit_logs to authenticated;
grant select on public.beneficiaries to authenticated;
grant insert (preferred_language, sensitive_data, created_by) on public.beneficiaries to authenticated;
grant update (preferred_language, sensitive_data) on public.beneficiaries to authenticated;
grant select on public.assistance_requests to authenticated;
grant insert (beneficiary_id, channel, language, needs_summary, contact_data, consent_record, created_by)
  on public.assistance_requests to authenticated;
grant update (status, needs_summary, contact_data, consent_record, closed_at)
  on public.assistance_requests to authenticated;
grant select on public.case_assignments to authenticated;
grant select on public.case_notes to authenticated;
grant insert (assistance_request_id, author_id, body) on public.case_notes to authenticated;
grant select, insert, update on public.programs, public.program_activities to authenticated;
grant select on public.donors, public.donations, public.payment_transactions to authenticated;
grant select on public.partners, public.partnership_requests, public.contact_messages to authenticated;
grant select, insert, update on public.news to authenticated;

create policy profiles_select_self_or_admin
on public.profiles for select to authenticated
using (
  public.is_active_staff()
  and (id = (select auth.uid()) or public.has_any_role(array['super_admin', 'admin']::text[]))
);

create policy profiles_update_self
on public.profiles for update to authenticated
using (id = (select auth.uid()) and public.is_active_staff())
with check (id = (select auth.uid()) and public.is_active_staff());

create policy roles_select_active_staff
on public.roles for select to authenticated
using (public.is_active_staff());

create policy profile_roles_select_self_or_admin
on public.profile_roles for select to authenticated
using (
  public.is_active_staff()
  and (profile_id = (select auth.uid()) or public.has_any_role(array['super_admin', 'admin']::text[]))
);

create policy audit_logs_select_admin
on public.audit_logs for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy beneficiaries_select_authorized
on public.beneficiaries for select to authenticated
using (public.can_access_beneficiary(id));

create policy beneficiaries_insert_admin
on public.beneficiaries for insert to authenticated
with check (
  public.has_any_role(array['super_admin', 'admin']::text[])
  and created_by = (select auth.uid())
);

create policy beneficiaries_update_authorized
on public.beneficiaries for update to authenticated
using (
  public.can_access_beneficiary(id)
  and public.has_any_role(array['super_admin', 'admin', 'social_worker']::text[])
)
with check (
  public.can_access_beneficiary(id)
  and public.has_any_role(array['super_admin', 'admin', 'social_worker']::text[])
);

create policy assistance_requests_select_authorized
on public.assistance_requests for select to authenticated
using (public.can_access_assistance_request(id));

create policy assistance_requests_insert_admin
on public.assistance_requests for insert to authenticated
with check (
  public.has_any_role(array['super_admin', 'admin']::text[])
  and channel = 'internal'
  and created_by = (select auth.uid())
);

create policy assistance_requests_update_authorized
on public.assistance_requests for update to authenticated
using (
  public.can_access_assistance_request(id)
  and public.has_any_role(array['super_admin', 'admin', 'social_worker']::text[])
)
with check (
  public.can_access_assistance_request(id)
  and public.has_any_role(array['super_admin', 'admin', 'social_worker']::text[])
);

create policy case_assignments_select_participant_or_admin
on public.case_assignments for select to authenticated
using (
  public.is_active_staff()
  and (assignee_id = (select auth.uid()) or assigned_by = (select auth.uid())
       or public.has_any_role(array['super_admin', 'admin']::text[]))
);

create policy case_notes_select_authorized
on public.case_notes for select to authenticated
using (public.can_access_assistance_request(assistance_request_id));

create policy case_notes_insert_authorized
on public.case_notes for insert to authenticated
with check (
  author_id = (select auth.uid())
  and public.has_any_role(array['super_admin', 'admin', 'social_worker']::text[])
  and public.can_access_assistance_request(assistance_request_id)
);

create policy programs_select_management
on public.programs for select to authenticated
using (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy programs_insert_management
on public.programs for insert to authenticated
with check (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy programs_update_management
on public.programs for update to authenticated
using (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]))
with check (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy program_activities_select_management
on public.program_activities for select to authenticated
using (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy program_activities_insert_management
on public.program_activities for insert to authenticated
with check (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy program_activities_update_management
on public.program_activities for update to authenticated
using (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]))
with check (public.has_any_role(array['super_admin', 'admin', 'program_manager']::text[]));

create policy donors_select_admin
on public.donors for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy donations_select_admin
on public.donations for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy payment_transactions_select_admin
on public.payment_transactions for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy partners_select_admin
on public.partners for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy partnership_requests_select_admin
on public.partnership_requests for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy contact_messages_select_admin
on public.contact_messages for select to authenticated
using (public.has_any_role(array['super_admin', 'admin']::text[]));

create policy news_select_editor
on public.news for select to authenticated
using (
  public.has_any_role(array['super_admin', 'admin']::text[])
  or (author_id = (select auth.uid()) and public.has_any_role(array['content_editor']::text[]))
);

create policy news_insert_editor
on public.news for insert to authenticated
with check (
  public.has_any_role(array['super_admin', 'admin', 'content_editor']::text[])
  and author_id = (select auth.uid())
);

create policy news_update_editor
on public.news for update to authenticated
using (
  public.has_any_role(array['super_admin', 'admin']::text[])
  or (author_id = (select auth.uid()) and public.has_any_role(array['content_editor']::text[]))
)
with check (
  public.has_any_role(array['super_admin', 'admin']::text[])
  or (author_id = (select auth.uid()) and public.has_any_role(array['content_editor']::text[]))
);

-- No policies or grants are added for anon. Staff invitations and role changes
-- are performed only by authenticated Edge Functions using server credentials.
