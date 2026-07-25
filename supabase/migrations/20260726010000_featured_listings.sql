-- Featured listings: a landlord pays a flat fee (currently by manual bank
-- transfer, confirmed by an admin — there is no payment gateway yet) to
-- have a listing promoted for a fixed number of days.
alter table public.properties
  add column featured boolean not null default false,
  add column featured_until timestamptz;

create table public.featured_requests (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  amount_lak bigint not null,
  duration_days int not null,
  proof_image_url text,
  status text not null default 'pending_review'
    check (status in ('pending_review', 'confirmed', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table public.featured_requests enable row level security;

create policy "Owners can view their own feature requests"
  on public.featured_requests for select
  using (
    auth.uid() = owner_id
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Owners can request featuring for their own properties"
  on public.featured_requests for insert
  with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.properties p
      where p.id = property_id and p.owner_id = auth.uid()
    )
  );

create policy "Admins can review feature requests"
  on public.featured_requests for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));
