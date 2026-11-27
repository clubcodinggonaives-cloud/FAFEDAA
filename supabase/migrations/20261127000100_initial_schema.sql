-- FAFEDAA initial application schema. Apply only to a development/staging project first.
-- RLS is enabled on every application table; policies are intentionally added in Lot 2.

create type public.assistance_request_status as enum (
  'received', 'under_review', 'assessment', 'approved',
  'assistance_in_progress', 'completed', 'rejected'
);
create type public.donation_status as enum ('pending', 'verified', 'failed', 'refunded');
create type public.donation_kind as enum ('financial', 'in_kind');
create type public.payment_provider as enum ('manual', 'simulation', 'external');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  display_name text not null,
  preferred_language text not null default 'fr' check (preferred_language in ('fr', 'ht', 'en')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id smallint generated always as identity primary key,
  name text not null unique check (name in ('super_admin', 'admin', 'program_manager', 'social_worker', 'content_editor')),
  description text,
  created_at timestamptz not null default now()
);

insert into public.roles (name, description) values
  ('super_admin', 'Administration globale contrôlée'),
  ('admin', 'Administration de l’organisation'),
  ('program_manager', 'Gestion des programmes'),
  ('social_worker', 'Traitement des dossiers autorisés'),
  ('content_editor', 'Gestion des contenus publics');

create table public.profile_roles (
  profile_id uuid not null references public.profiles(id) on delete restrict,
  role_id smallint not null references public.roles(id) on delete restrict,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (profile_id, role_id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.beneficiaries (
  id uuid primary key default gen_random_uuid(),
  case_reference text not null unique default gen_random_uuid()::text,
  status text not null default 'active' check (status in ('active', 'archived', 'anonymized')),
  preferred_language text check (preferred_language in ('fr', 'ht', 'en')),
  sensitive_data jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.assistance_requests (
  id uuid primary key default gen_random_uuid(),
  public_reference text not null unique default gen_random_uuid()::text,
  beneficiary_id uuid references public.beneficiaries(id) on delete set null,
  status public.assistance_request_status not null default 'received',
  channel text not null check (channel in ('public', 'internal')),
  language text not null default 'fr' check (language in ('fr', 'ht', 'en')),
  needs_summary text not null,
  contact_data jsonb not null default '{}'::jsonb,
  consent_record jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz
);

create table public.case_assignments (
  id uuid primary key default gen_random_uuid(),
  assistance_request_id uuid not null references public.assistance_requests(id) on delete restrict,
  assignee_id uuid not null references public.profiles(id) on delete restrict,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  check (ended_at is null or ended_at >= assigned_at)
);

create table public.case_notes (
  id uuid primary key default gen_random_uuid(),
  assistance_request_id uuid not null references public.assistance_requests(id) on delete restrict,
  author_id uuid references public.profiles(id) on delete set null,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.programs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  status text not null default 'draft' check (status in ('draft', 'active', 'completed', 'archived')),
  translations jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.program_activities (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete restrict,
  status text not null default 'planned' check (status in ('planned', 'in_progress', 'completed', 'cancelled')),
  translations jsonb not null default '{}'::jsonb,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at >= starts_at)
);

create table public.donors (
  id uuid primary key default gen_random_uuid(),
  contact_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid references public.donors(id) on delete set null,
  kind public.donation_kind not null,
  amount numeric(14, 2),
  quantity numeric(14, 3),
  currency text,
  description text,
  method text not null,
  status public.donation_status not null default 'pending',
  transaction_reference text,
  recorded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((kind = 'financial' and amount is not null and amount > 0 and currency is not null and quantity is null) or
         (kind = 'in_kind' and quantity is not null and quantity > 0 and amount is null))
);

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  donation_id uuid not null references public.donations(id) on delete restrict,
  provider public.payment_provider not null default 'manual',
  provider_reference text,
  idempotency_key text not null unique default encode(gen_random_bytes(16), 'hex'),
  amount numeric(14, 2) not null check (amount > 0),
  currency text not null,
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed', 'cancelled')),
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_reference)
);

create table public.partners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact_data jsonb not null default '{}'::jsonb,
  status text not null default 'prospective' check (status in ('prospective', 'active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.partnership_requests (
  id uuid primary key default gen_random_uuid(),
  organization_name text not null,
  contact_data jsonb not null default '{}'::jsonb,
  message text not null,
  status text not null default 'received' check (status in ('received', 'reviewing', 'accepted', 'declined', 'closed')),
  created_at timestamptz not null default now()
);

create table public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text not null,
  language text not null default 'fr' check (language in ('fr', 'ht', 'en')),
  status text not null default 'unread' check (status in ('unread', 'read', 'replied', 'archived')),
  created_at timestamptz not null default now()
);

create table public.news (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  translations jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  author_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
revoke all privileges on function public.set_updated_at() from public, anon, authenticated;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger beneficiaries_set_updated_at before update on public.beneficiaries
  for each row execute function public.set_updated_at();
create trigger assistance_requests_set_updated_at before update on public.assistance_requests
  for each row execute function public.set_updated_at();
create trigger programs_set_updated_at before update on public.programs
  for each row execute function public.set_updated_at();
create trigger donations_set_updated_at before update on public.donations
  for each row execute function public.set_updated_at();
create trigger payment_transactions_set_updated_at before update on public.payment_transactions
  for each row execute function public.set_updated_at();
create trigger partners_set_updated_at before update on public.partners
  for each row execute function public.set_updated_at();
create trigger news_set_updated_at before update on public.news
  for each row execute function public.set_updated_at();

create index profiles_active_idx on public.profiles (is_active);
create index profile_roles_role_idx on public.profile_roles (role_id, profile_id);
create index audit_logs_actor_created_idx on public.audit_logs (actor_id, created_at desc);
create index beneficiaries_status_created_idx on public.beneficiaries (status, created_at desc);
create index assistance_requests_status_created_idx on public.assistance_requests (status, created_at desc);
create index assistance_requests_beneficiary_idx on public.assistance_requests (beneficiary_id);
create index case_assignments_assignee_idx on public.case_assignments (assignee_id, ended_at);
create index case_assignments_request_idx on public.case_assignments (assistance_request_id, assigned_at desc);
create index case_notes_request_created_idx on public.case_notes (assistance_request_id, created_at desc);
create index program_activities_program_idx on public.program_activities (program_id, starts_at);
create index donations_created_idx on public.donations (created_at desc);
create index donations_donor_idx on public.donations (donor_id);
create index payment_transactions_donation_idx on public.payment_transactions (donation_id, created_at desc);
create index partnership_requests_status_created_idx on public.partnership_requests (status, created_at desc);
create index contact_messages_status_created_idx on public.contact_messages (status, created_at desc);
create index news_published_idx on public.news (published_at desc) where status = 'published';

-- No direct table access is allowed until reviewed policies are shipped in Lot 2.
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.profile_roles enable row level security;
alter table public.audit_logs enable row level security;
alter table public.beneficiaries enable row level security;
alter table public.assistance_requests enable row level security;
alter table public.case_assignments enable row level security;
alter table public.case_notes enable row level security;
alter table public.programs enable row level security;
alter table public.program_activities enable row level security;
alter table public.donors enable row level security;
alter table public.donations enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.partners enable row level security;
alter table public.partnership_requests enable row level security;
alter table public.contact_messages enable row level security;
alter table public.news enable row level security;

-- Defense in depth: do not rely on the project's default table grants.
revoke all privileges on table
  public.profiles, public.roles, public.profile_roles, public.audit_logs,
  public.beneficiaries, public.assistance_requests, public.case_assignments, public.case_notes,
  public.programs, public.program_activities, public.donors, public.donations,
  public.payment_transactions, public.partners, public.partnership_requests,
  public.contact_messages, public.news
from anon, authenticated;
revoke all privileges on table
  public.profiles, public.roles, public.profile_roles, public.audit_logs,
  public.beneficiaries, public.assistance_requests, public.case_assignments, public.case_notes,
  public.programs, public.program_activities, public.donors, public.donations,
  public.payment_transactions, public.partners, public.partnership_requests,
  public.contact_messages, public.news
from public;
grant all privileges on table
  public.profiles, public.roles, public.profile_roles, public.audit_logs,
  public.beneficiaries, public.assistance_requests, public.case_assignments, public.case_notes,
  public.programs, public.program_activities, public.donors, public.donations,
  public.payment_transactions, public.partners, public.partnership_requests,
  public.contact_messages, public.news
to service_role;
revoke all privileges on sequence public.roles_id_seq from public, anon, authenticated;
grant usage, select on sequence public.roles_id_seq to service_role;
-- Companion rollback: supabase/rollback/20261127000100_initial_schema.down.sql.
