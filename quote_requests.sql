-- DriveCare public quote request inbox. Run once in Supabase SQL Editor.
-- Public visitors may SUBMIT but cannot READ, EDIT, or DELETE requests.
-- This is a lead form, NOT a customer account or paid subscription.
create table if not exists public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  customer_name text not null check (length(trim(customer_name)) between 2 and 120),
  customer_phone text not null check (length(trim(customer_phone)) between 7 and 30),
  customer_email text not null check (length(trim(customer_email)) between 3 and 254),
  customer_city text,
  quote_type text not null check (quote_type in ('individual','fleet')),
  company_name text,
  vehicle_count integer not null check (vehicle_count between 1 and 100),
  vehicle_category text check (vehicle_category in ('standard','euro')),
  vehicle_year integer check (vehicle_year between 1900 and 2100),
  vehicle_make text,
  vehicle_model text,
  vehicle_mileage integer check (vehicle_mileage between 0 and 2000000),
  vehicle_vin text check (vehicle_vin is null or length(vehicle_vin)=17),
  plan_name text not null check (length(plan_name) between 2 and 80),
  payment_term integer not null check (payment_term in (1,6,12)),
  quoted_total numeric(12,2) not null check (quoted_total >= 0),
  quoted_savings numeric(12,2) not null default 0 check (quoted_savings >= 0),
  notes text check (notes is null or length(notes)<=1500),
  status text not null default 'new' check (status in ('new','contacted','approved','declined')),
  constraint valid_vehicle_details check (
    (quote_type='individual' and vehicle_count=1 and vehicle_year is not null and length(trim(vehicle_make))>0 and length(trim(vehicle_model))>0)
    or (quote_type='fleet' and vehicle_count>=3 and length(trim(company_name))>0)
  )
);
alter table public.quote_requests enable row level security;
revoke all on public.quote_requests from anon, authenticated;
grant insert on public.quote_requests to anon, authenticated;
-- If this SQL is run again, do not create a duplicate policy.
drop policy if exists quote_requests_public_insert on public.quote_requests;
create policy quote_requests_public_insert on public.quote_requests
  for insert to anon, authenticated with check (status='new');
-- No SELECT policy for the public website. Review incoming requests in Supabase Table Editor
-- using your Supabase dashboard owner account. Never expose a service_role key in HTML.
-- Before public launch, add server-side spam/rate protection (e.g. CAPTCHA + Edge Function),
-- verify business contact details and publish a privacy notice.
