-- Both select policies had a branch with no auth.uid() reference at all,
-- so — unlike every other "visible once approved/pending" policy in this
-- schema, which is intentionally public browsing (e.g. approved
-- properties) — these accidentally exposed private data to anyone,
-- including a logged-out anon caller with just the public anon key:
--   - moving_requests: "or status = 'pending'" leaked every open job's
--     pickup/dropoff address, date, and notes to the whole internet.
--   - drivers: "or status = 'approved'" leaked every approved driver's
--     phone number and live GPS coordinates to the whole internet.
-- Scoped both back down to what the original comments actually describe:
-- pending jobs are for approved drivers browsing to claim, and a driver's
-- details are for themselves, admins, or the specific customer whose job
-- they're assigned to.

drop policy "Moving requests visible to customer, eligible drivers, admins" on public.moving_requests;

create policy "Moving requests visible to customer, eligible drivers, admins"
  on public.moving_requests for select
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

drop policy "Drivers visible to self, admins, or once approved" on public.drivers;

create policy "Drivers visible to self, admins, or their assigned customer"
  on public.drivers for select
  using (
    user_id = auth.uid()
    or exists (select 1 from public.admins where user_id = auth.uid())
    or exists (
      select 1 from public.moving_requests
      where moving_requests.driver_id = drivers.id
        and moving_requests.customer_id = auth.uid()
    )
  );
