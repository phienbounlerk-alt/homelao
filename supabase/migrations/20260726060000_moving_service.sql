-- Phase 1 of the moving/transport service: driver registration (admin-
-- moderated, same pattern as listings) and a request/accept/status flow for
-- customers to book a truck. No live GPS tracking yet — that needs drivers
-- actively using the app during a job, which only makes sense once real
-- drivers are registered.

create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  driver_name text not null,
  phone text not null,
  vehicle_type text not null
    check (vehicle_type in ('ລົດກະບະ', 'ລົດບັນທຸກກາງ', 'ລົດບັນທຸກໃຫຍ່')),
  vehicle_plate text not null,
  vehicle_photo_url text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.drivers enable row level security;

-- A driver's own (pending/rejected) profile is only visible to themselves
-- and admins; once approved, customers browsing accepted jobs can see the
-- assigned driver's public details via the moving_requests join below.
create policy "Drivers visible to self, admins, or once approved"
  on public.drivers for select
  using (
    status = 'approved'
    or user_id = auth.uid()
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Users can register as a driver"
  on public.drivers for insert
  with check (user_id = auth.uid());

create policy "Admins can moderate any driver"
  on public.drivers for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));

create table public.moving_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users (id) on delete cascade,
  driver_id uuid references public.drivers (id) on delete set null,
  pickup_location text not null,
  dropoff_location text not null,
  vehicle_type text not null
    check (vehicle_type in ('ລົດກະບະ', 'ລົດບັນທຸກກາງ', 'ລົດບັນທຸກໃຫຍ່')),
  preferred_date date not null,
  notes text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  completed_at timestamptz
);

alter table public.moving_requests enable row level security;

-- Visible to: the customer who made it, any approved driver browsing open
-- jobs, the driver it's assigned to, and admins.
create policy "Moving requests visible to customer, eligible drivers, admins"
  on public.moving_requests for select
  using (
    customer_id = auth.uid()
    or status = 'pending'
    or driver_id in (select id from public.drivers where user_id = auth.uid())
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Customers can create their own moving request"
  on public.moving_requests for insert
  with check (customer_id = auth.uid());

-- Covers: customer cancelling their own pending request, an approved driver
-- claiming a still-pending request (driver_id isn't theirs yet, so this is
-- gated on status + driver approval rather than driver_id), the assigned
-- driver progressing status, and admin override.
create policy "Customer, claiming/assigned driver, or admin can update"
  on public.moving_requests for update
  using (
    customer_id = auth.uid()
    or driver_id in (select id from public.drivers where user_id = auth.uid())
    or (
      status = 'pending'
      and exists (
        select 1 from public.drivers
        where user_id = auth.uid() and status = 'approved'
      )
    )
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

alter publication supabase_realtime add table public.drivers;
alter publication supabase_realtime add table public.moving_requests;

create index drivers_user_id_idx on public.drivers (user_id);
create index moving_requests_customer_id_idx on public.moving_requests (customer_id, created_at desc);
create index moving_requests_status_idx on public.moving_requests (status, created_at);
create index moving_requests_driver_id_idx on public.moving_requests (driver_id);
