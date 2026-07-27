-- Owner identity verification. Documents (ID photo, selfie, ownership
-- proof) are stored in a private bucket (see below) — this table only
-- holds the paths/metadata and the review workflow, never publicly
-- readable data.
create table public.owner_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  id_document_url text,
  selfie_url text,
  ownership_document_url text,
  phone_number text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'more_docs_requested')),
  admin_notes text,
  reviewed_by uuid references auth.users (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One active submission per user — resubmission updates the same row
-- (mirrors the drivers/properties resubmit pattern) rather than
-- accumulating duplicate pending rows.
create unique index owner_verifications_user_id_key
  on public.owner_verifications (user_id);

alter table public.owner_verifications enable row level security;

create policy "Owners can view their own verification"
  on public.owner_verifications for select
  using (
    user_id = auth.uid()
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

-- Trust gap closed the same way as properties/drivers/moving_requests: the
-- owner's own insert can only ever land in 'pending' with no reviewer
-- fields set, so a raw API call can't self-approve.
create policy "Owners can submit their own verification"
  on public.owner_verifications for insert
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
  );

-- Resubmission after rejection/more-docs-requested re-queues to 'pending'
-- and clears the previous reviewer's decision — same shape as
-- 20260726070000_driver_resubmit.sql.
create policy "Owners can resubmit after rejection or a docs request"
  on public.owner_verifications for update
  using (
    user_id = auth.uid()
    and status in ('rejected', 'more_docs_requested')
  )
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
  );

create policy "Admins can review any verification"
  on public.owner_verifications for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));

create index owner_verifications_status_idx
  on public.owner_verifications (status);

-- Private bucket for verification documents — unlike the existing public
-- `photos` bucket, these are government ID photos and selfies and must
-- never be readable without auth. Files live at
-- {auth.uid()}/{id_document|selfie|ownership}/{filename}, mirroring the
-- {auth.uid()}/{folder}/{filename} convention from 20260725110000, but
-- with select scoped to the owner + admins instead of public.
insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do nothing;

create policy "Owners and admins can view verification documents"
  on storage.objects for select
  using (
    bucket_id = 'verification-docs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (select 1 from public.admins where user_id = auth.uid())
    )
  );

create policy "Owners can upload their own verification documents"
  on storage.objects for insert
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Owners can replace their own verification documents"
  on storage.objects for update
  using (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- `properties.verified` has existed since the initial schema but was never
-- actually written anywhere — it defaulted to true and just sat there as
-- an inert decorative flag. This repurposes it to mean "this listing's
-- owner is a verified owner," kept in sync automatically (see trigger
-- below) rather than settable directly, and starts false for every
-- existing listing since no owner has gone through verification yet.
alter table public.properties alter column verified set default false;
update public.properties set verified = false;

-- Extra defense-in-depth alongside the trigger: even if the trigger were
-- ever removed, an owner's own insert/update still can't set verified
-- true directly — only the trigger (running as the table owner, not
-- through RLS) can.
drop policy "Owners can insert their own properties" on public.properties;

create policy "Owners can insert their own properties"
  on public.properties for insert
  with check (
    auth.uid() = owner_id
    and status = 'pending'
    and featured = false
    and featured_until is null
    and rating = 0
    and views = 0
    and verified = false
  );

drop policy "Owners can update their own properties" on public.properties;

create policy "Owners can update their own properties"
  on public.properties for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id and status = 'pending' and verified = false);

-- Keeps every one of an owner's listings' `verified` flag in lockstep with
-- their current verification status, the moment an admin decides it —
-- security definer so it can write `properties` regardless of who
-- triggered the update (the admin, via their own RLS-limited session).
create or replace function public.sync_owner_verified_badge()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.properties
  set verified = (new.status = 'approved')
  where owner_id = new.user_id
    and verified is distinct from (new.status = 'approved');
  return new;
end;
$$;

create trigger owner_verification_status_change
  after insert or update of status on public.owner_verifications
  for each row
  execute function public.sync_owner_verified_badge();
