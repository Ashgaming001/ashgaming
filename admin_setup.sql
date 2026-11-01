-- ASH GAMING admin security + game cover uploads
-- Run this entire file in Supabase Dashboard > SQL Editor > New query.
-- IMPORTANT: first create your admin login in Authentication > Users.
-- After running this script, copy that user's UUID and run the INSERT at the bottom.

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.store_admins enable row level security;

drop policy if exists "Admins can view their own admin record" on public.store_admins;
create policy "Admins can view their own admin record"
on public.store_admins for select
to authenticated
using (user_id = auth.uid());

create or replace function public.is_store_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.store_admins
    where user_id = auth.uid()
  );
$$;

revoke all on function public.is_store_admin() from public;
grant execute on function public.is_store_admin() to anon, authenticated;

-- Remove previous products policies so an older broad authenticated-user policy
-- cannot accidentally let ordinary users add or change games.
do $$
declare p record;
begin
  for p in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'products'
  loop
    execute format('drop policy if exists %I on public.products', p.policyname);
  end loop;
end $$;

alter table public.products enable row level security;

create policy "Anyone can read active games"
on public.products for select
to anon, authenticated
using (active = true or public.is_store_admin());

create policy "Only store admins can add games"
on public.products for insert
to authenticated
with check (public.is_store_admin());

create policy "Only store admins can edit games"
on public.products for update
to authenticated
using (public.is_store_admin())
with check (public.is_store_admin());

create policy "Only store admins can delete games"
on public.products for delete
to authenticated
using (public.is_store_admin());

-- Public image URLs are readable; only admins can upload/change/remove cover files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('game-covers', 'game-covers', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = true, file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "Public can view ASH game covers" on storage.objects;
create policy "Public can view ASH game covers"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'game-covers');

drop policy if exists "Store admins can upload ASH game covers" on storage.objects;
create policy "Store admins can upload ASH game covers"
on storage.objects for insert
to authenticated
with check (bucket_id = 'game-covers' and public.is_store_admin());

drop policy if exists "Store admins can update ASH game covers" on storage.objects;
create policy "Store admins can update ASH game covers"
on storage.objects for update
to authenticated
using (bucket_id = 'game-covers' and public.is_store_admin())
with check (bucket_id = 'game-covers' and public.is_store_admin());

drop policy if exists "Store admins can delete ASH game covers" on storage.objects;
create policy "Store admins can delete ASH game covers"
on storage.objects for delete
to authenticated
using (bucket_id = 'game-covers' and public.is_store_admin());

-- AFTER creating your admin login, replace the UUID below and run this one line:
-- insert into public.store_admins (user_id) values ('PASTE-ADMIN-USER-UUID-HERE');
