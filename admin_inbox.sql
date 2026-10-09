-- DriveCare admin inbox migration. Run in Supabase SQL Editor AFTER schema.sql and quote_requests.sql.
-- This assumes public.is_admin() from schema.sql checks profiles.role securely.
-- Customer/anonymous users can submit inquiries, but cannot read them.
alter table public.quote_requests enable row level security;
grant select on public.quote_requests to authenticated;
-- Restrict UPDATE to status only, even for authenticated users.
revoke update on public.quote_requests from anon, authenticated;
grant update (status) on public.quote_requests to authenticated;
drop policy if exists quote_requests_admin_read on public.quote_requests;
create policy quote_requests_admin_read on public.quote_requests
 for select to authenticated using (public.is_admin());
drop policy if exists quote_requests_admin_status on public.quote_requests;
create policy quote_requests_admin_status on public.quote_requests
 for update to authenticated using (public.is_admin()) with check (public.is_admin());
-- IMPORTANT: Existing public INSERT policy remains; do not grant public SELECT.
-- Admin approval here is only a workflow label, not payment/activation.
