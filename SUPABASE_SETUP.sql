-- Jalankan di Supabase SQL Editor. Ganti email admin di bawah dengan email akun Auth milikmu.
create extension if not exists pgcrypto;
create table if not exists public.omix_orders (
 id uuid primary key default gen_random_uuid(),
 order_code text not null unique,
 customer_name text not null,
 contact text not null,
 service text not null,
 budget text,
 details text,
 status text not null default 'Menunggu konfirmasi' check(status in ('Menunggu konfirmasi','Diproses','Selesai','Dibatalkan')),
 created_at timestamptz not null default now()
);
alter table public.omix_orders enable row level security;
drop policy if exists omix_public_insert on public.omix_orders;
drop policy if exists omix_admin_read on public.omix_orders;
drop policy if exists omix_admin_update on public.omix_orders;
create policy omix_public_insert on public.omix_orders for insert to anon,authenticated
with check(length(trim(customer_name)) between 1 and 60 and length(trim(contact)) between 1 and 80 and service in ('Poster Turnamen','Thumbnail Gaming','Paket Branding Tim') and length(coalesce(details,''))<=1000);
create policy omix_admin_read on public.omix_orders for select to authenticated using(auth.jwt()->>'email'='email_admin_kamu@example.com');
create policy omix_admin_update on public.omix_orders for update to authenticated using(auth.jwt()->>'email'='email_admin_kamu@example.com') with check(auth.jwt()->>'email'='email_admin_kamu@example.com');
create or replace function public.omix_track_order(p_code text)
returns table(order_code text,service text,status text,created_at timestamptz)
language sql security definer set search_path=public as $$
 select o.order_code,o.service,o.status,o.created_at from public.omix_orders o where o.order_code=upper(trim(p_code)) limit 1;
$$;
revoke all on function public.omix_track_order(text) from public;
grant execute on function public.omix_track_order(text) to anon,authenticated;
grant insert on public.omix_orders to anon,authenticated;
grant select,update on public.omix_orders to authenticated;
