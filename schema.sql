-- DriveCare starter schema for Supabase PostgreSQL.
-- Run in Supabase SQL Editor. Do not place service_role keys in browser code.
create extension if not exists pgcrypto;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', phone text, role text not null default 'customer' check (role in ('customer','admin')),
 created_at timestamptz not null default now()
);
create table public.fleets (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 company_name text not null, created_at timestamptz not null default now()
);
create table public.vehicles (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 fleet_id uuid references public.fleets(id), year integer not null check (year between 1900 and 2100),
 make text not null, model text not null, trim text, mileage integer check (mileage >= 0),
 vin text check (vin is null or length(vin) = 17), plate text,
 created_at timestamptz not null default now()
);
create table public.membership_requests (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 vehicle_id uuid not null references public.vehicles(id),
 plan text not null check (plan in ('Essential','Plus','Premium','Euro Essential','Euro Plus','Euro Premium','Fleet Essential','Fleet Plus','Fleet Premium','Fleet Custom')),
 payment_term integer not null check (payment_term in (1,6,12)),
 status text not null default 'pending' check (status in ('pending','approved','declined','cancelled')),
 note text, created_at timestamptz not null default now()
);
create table public.service_requests (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 vehicle_id uuid not null references public.vehicles(id),
 concern text not null, preferred_date date, status text not null default 'new' check (status in ('new','contacted','scheduled','completed','cancelled')),
 created_at timestamptz not null default now()
);
create table public.service_records (
 id uuid primary key default gen_random_uuid(), vehicle_id uuid not null references public.vehicles(id),
 service_date date not null, mileage integer, description text not null, created_at timestamptz not null default now()
);
create or replace function public.create_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.create_profile();
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id = (select auth.uid()) and role = 'admin'); $$;
create or replace function public.owns_vehicle(v uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.vehicles where id=v and owner_id=(select auth.uid())); $$;
create or replace function public.owns_fleet(f uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.fleets where id=f and owner_id=(select auth.uid())); $$;
alter table public.profiles enable row level security;
alter table public.fleets enable row level security;
alter table public.vehicles enable row level security;
alter table public.membership_requests enable row level security;
alter table public.service_requests enable row level security;
alter table public.service_records enable row level security;
create policy profiles_read on public.profiles for select to authenticated using (id=(select auth.uid()) or public.is_admin());
-- Profile updates intentionally disabled until a safe column-specific update function is added.
create policy fleets_read on public.fleets for select to authenticated using (owner_id=(select auth.uid()) or public.is_admin());
create policy fleets_insert on public.fleets for insert to authenticated with check (owner_id=(select auth.uid()));
create policy fleets_update on public.fleets for update to authenticated using (owner_id=(select auth.uid()) or public.is_admin()) with check (owner_id=(select auth.uid()) or public.is_admin());
create policy vehicles_read on public.vehicles for select to authenticated using (owner_id=(select auth.uid()) or public.is_admin());
create policy vehicles_insert on public.vehicles for insert to authenticated with check (owner_id=(select auth.uid()) and (fleet_id is null or public.owns_fleet(fleet_id)));
create policy vehicles_update on public.vehicles for update to authenticated using (owner_id=(select auth.uid()) or public.is_admin()) with check ((owner_id=(select auth.uid()) and (fleet_id is null or public.owns_fleet(fleet_id))) or public.is_admin());
create policy membership_read on public.membership_requests for select to authenticated using (owner_id=(select auth.uid()) or public.is_admin());
create policy membership_insert on public.membership_requests for insert to authenticated with check (owner_id=(select auth.uid()) and public.owns_vehicle(vehicle_id) and status='pending');
create policy membership_admin_update on public.membership_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy service_read on public.service_requests for select to authenticated using (owner_id=(select auth.uid()) or public.is_admin());
create policy service_insert on public.service_requests for insert to authenticated with check (owner_id=(select auth.uid()) and public.owns_vehicle(vehicle_id) and status='new');
create policy service_admin_update on public.service_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy records_read on public.service_records for select to authenticated using (public.owns_vehicle(vehicle_id) or public.is_admin());
create policy records_admin_insert on public.service_records for insert to authenticated with check (public.is_admin());
create policy records_admin_update on public.service_records for update to authenticated using (public.is_admin()) with check (public.is_admin());
-- After you sign up, promote your own user in the SQL editor (replace with your auth.users UUID):
-- update public.profiles set role='admin' where id='YOUR-AUTH-USER-UUID';
