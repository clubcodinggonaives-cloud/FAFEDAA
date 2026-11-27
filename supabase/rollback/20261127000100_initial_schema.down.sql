-- Destructive rollback for the initial schema. Only use on a disposable environment
-- or after a reviewed backup and explicit change approval.
drop table if exists public.news;
drop table if exists public.contact_messages;
drop table if exists public.partnership_requests;
drop table if exists public.partners;
drop table if exists public.payment_transactions;
drop table if exists public.donations;
drop table if exists public.donors;
drop table if exists public.program_activities;
drop table if exists public.programs;
drop table if exists public.case_notes;
drop table if exists public.case_assignments;
drop table if exists public.assistance_requests;
drop table if exists public.beneficiaries;
drop table if exists public.audit_logs;
drop table if exists public.profile_roles;
drop table if exists public.roles;
drop table if exists public.profiles;
drop function if exists public.set_updated_at();
drop type if exists public.payment_provider;
drop type if exists public.donation_kind;
drop type if exists public.donation_status;
drop type if exists public.assistance_request_status;
