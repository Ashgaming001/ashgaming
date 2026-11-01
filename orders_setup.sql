-- ASH GAMING: customer orders
-- Run this once in Supabase SQL Editor for project xqdiumkisbtkjcgfuyzc.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_phone text not null,
  delivery_address text not null,
  game_name text not null,
  product_id uuid,
  price numeric(10,2) not null default 200,
  platform text not null default 'PS4',
  status text not null default 'new'
    check (status in ('new','completed','cancelled')),
  created_at timestamptz not null default now()
);

alter table public.orders enable row level security;

-- Customers can submit a new order, but cannot read customer orders.
drop policy if exists "Anyone can submit a new order" on public.orders;
create policy "Anyone can submit a new order"
on public.orders for insert
to anon, authenticated
with check (status = 'new');

-- Only approved store admins can view, update, or delete orders.
drop policy if exists "Store admins can view orders" on public.orders;
create policy "Store admins can view orders"
on public.orders for select
to authenticated
using (public.is_store_admin());

drop policy if exists "Store admins can update orders" on public.orders;
create policy "Store admins can update orders"
on public.orders for update
to authenticated
using (public.is_store_admin())
with check (public.is_store_admin());

drop policy if exists "Store admins can delete orders" on public.orders;
create policy "Store admins can delete orders"
on public.orders for delete
to authenticated
using (public.is_store_admin());

grant insert on public.orders to anon, authenticated;
grant select, update, delete on public.orders to authenticated;
