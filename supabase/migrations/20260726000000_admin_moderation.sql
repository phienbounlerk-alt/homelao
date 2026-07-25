-- Admin roster. Only the service_role key can grant admin (no insert/update/
-- delete policy below); clients can only check their own membership.
create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.admins enable row level security;

create policy "Users can check their own admin status"
  on public.admins for select
  using (auth.uid() = user_id);

-- Listing moderation: new listings start pending and only become publicly
-- visible once an admin approves them. Existing listings are already live,
-- so they're backfilled to approved.
alter table public.properties
  add column status text not null default 'pending'
  check (status in ('pending', 'approved', 'rejected'));

update public.properties set status = 'approved';

drop policy "Properties are viewable by everyone" on public.properties;

create policy "Approved properties are viewable by everyone, own/admin always"
  on public.properties for select
  using (
    status = 'approved'
    or owner_id = auth.uid()
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Admins can moderate any property"
  on public.properties for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));
