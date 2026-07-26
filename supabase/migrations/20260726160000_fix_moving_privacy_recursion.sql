-- 20260726150000 introduced infinite recursion: the new moving_requests
-- select policy queries drivers, and the new drivers select policy queries
-- moving_requests, so evaluating either one re-triggers the other
-- indefinitely (Postgres error 42P17). Breaking the cycle the same way
-- update_driver_location already does elsewhere in this schema: wrap the
-- moving_requests -> drivers direction in security-definer functions,
-- whose function-owner role bypasses RLS internally, so evaluating them
-- never re-enters drivers' own policy. The drivers -> moving_requests
-- direction (a plain subquery) is then safe, since moving_requests'
-- policy no longer reads back through drivers' RLS at all.

create or replace function public.is_approved_driver()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.drivers
    where user_id = auth.uid() and status = 'approved'
  );
$$;

create or replace function public.my_driver_ids()
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select id from public.drivers where user_id = auth.uid();
$$;

drop policy "Moving requests visible to customer, eligible drivers, admins" on public.moving_requests;

create policy "Moving requests visible to customer, eligible drivers, admins"
  on public.moving_requests for select
  using (
    customer_id = auth.uid()
    or driver_id in (select public.my_driver_ids())
    or (status = 'pending' and public.is_approved_driver())
    or exists (select 1 from public.admins where user_id = auth.uid())
  );
