begin;
select plan(23);

select ok(
  (select count(*) = 17
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity),
  'RLS is enabled on all 17 application tables'
);

select is(
  (select count(*)::integer from pg_policies
   where schemaname = 'public' and roles && array['anon'::name, 'public'::name]),
  0,
  'No policy grants access to anon or PUBLIC'
);

select ok(not has_table_privilege('anon', 'public.beneficiaries', 'SELECT'), 'anon cannot select beneficiaries');
select ok(not has_table_privilege('anon', 'public.assistance_requests', 'INSERT'), 'anon cannot insert requests directly');
select ok(not has_table_privilege('authenticated', 'public.case_notes', 'DELETE'), 'staff cannot delete case notes');
select ok(has_table_privilege('authenticated', 'public.beneficiaries', 'SELECT'), 'authenticated role reaches RLS for beneficiaries');

select ok(
  has_table_privilege('service_role', 'public.donations', 'SELECT')
  and has_table_privilege('service_role', 'public.donations', 'INSERT')
  and has_table_privilege('service_role', 'public.donations', 'UPDATE')
  and has_table_privilege('service_role', 'public.donations', 'DELETE'),
  'service_role has server-side donation privileges'
);

select ok(not has_function_privilege('anon', 'public.is_active_staff()', 'EXECUTE'), 'anon cannot call staff authorization helpers');
select ok(has_function_privilege('authenticated', 'public.is_active_staff()', 'EXECUTE'), 'authenticated can evaluate staff authorization helpers');
select ok(not has_function_privilege('authenticated', 'public.provision_invited_staff(uuid,uuid,text,text,smallint)', 'EXECUTE'), 'authenticated cannot provision staff directly');
select ok(has_function_privilege('service_role', 'public.provision_invited_staff(uuid,uuid,text,text,smallint)', 'EXECUTE'), 'only the server role can provision invited staff');

set local request.jwt.claim.sub = '';
set local request.jwt.claims = '{}';
select ok(not public.is_active_staff(), 'a request with no user JWT is not active staff');

select is((select count(*)::integer from public.roles), 5, 'the five role definitions are seeded');
select is(
  (select count(*)::integer from pg_trigger
   where not tgisinternal and tgname like '%_set_updated_at'),
  8,
  'all eight updated_at triggers are installed'
);
select is(
  (select count(*)::integer from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in (
     'is_active_staff', 'has_any_role', 'can_access_assistance_request', 'can_access_beneficiary'
   ) and p.prosecdef),
  4,
  'all four authorization helpers are SECURITY DEFINER'
);

-- Synthetic identities and records exist only inside this rolled-back test transaction.
insert into auth.users (id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'worker-test@example.invalid', 'not-a-login-hash', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'editor-test@example.invalid', 'not-a-login-hash', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'admin-test@example.invalid', 'not-a-login-hash', now(), '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.profiles (id, display_name) values
  ('10000000-0000-4000-8000-000000000001', 'Synthetic worker'),
  ('10000000-0000-4000-8000-000000000002', 'Synthetic editor'),
  ('10000000-0000-4000-8000-000000000003', 'Synthetic admin');

insert into public.profile_roles (profile_id, role_id)
select '10000000-0000-4000-8000-000000000001', id from public.roles where name = 'social_worker';
insert into public.profile_roles (profile_id, role_id)
select '10000000-0000-4000-8000-000000000002', id from public.roles where name = 'content_editor';
insert into public.profile_roles (profile_id, role_id)
select '10000000-0000-4000-8000-000000000003', id from public.roles where name = 'admin';

insert into public.beneficiaries (id, created_by, sensitive_data)
values ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '{"synthetic":true}');
insert into public.assistance_requests (id, beneficiary_id, channel, needs_summary, created_by)
values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'internal', 'synthetic assigned case', '10000000-0000-4000-8000-000000000001'),
  ('30000000-0000-4000-8000-000000000002', null, 'internal', 'synthetic unassigned case', '10000000-0000-4000-8000-000000000003');
insert into public.case_assignments (assistance_request_id, assignee_id, assigned_by)
values ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003');

insert into public.donors (id, contact_data) values ('40000000-0000-4000-8000-000000000001', '{"synthetic":true}');
insert into public.donations (donor_id, kind, amount, currency, method)
values ('40000000-0000-4000-8000-000000000001', 'financial', 1, 'USD', 'test');
insert into public.news (slug, status, translations, author_id)
values
  ('synthetic-editor-story', 'draft', '{"en":{"title":"Synthetic"}}', '10000000-0000-4000-8000-000000000002'),
  ('synthetic-admin-story', 'draft', '{"en":{"title":"Synthetic admin"}}', '10000000-0000-4000-8000-000000000003');

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select count(*)::integer from public.assistance_requests), 1, 'social worker sees only their actively assigned case');
select is((select count(*)::integer from public.beneficiaries), 1, 'social worker sees beneficiary on assigned case');
select is((select count(*)::integer from public.profiles), 1, 'social worker sees only own profile');
select ok(not public.can_access_assistance_request('30000000-0000-4000-8000-000000000002'), 'social worker cannot probe into an unassigned case');

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000002';
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select count(*)::integer from public.donations), 0, 'content editor cannot see donations');
select is((select count(*)::integer from public.news), 1, 'content editor sees own news only');

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000003","role":"authenticated"}';
select is((select count(*)::integer from public.assistance_requests), 2, 'admin can see all assistance requests');
select is((select count(*)::integer from public.donations), 1, 'admin can see donations');

select * from finish();
rollback;
