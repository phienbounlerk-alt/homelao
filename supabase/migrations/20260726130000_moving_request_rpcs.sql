-- The broad "customer, claiming/assigned driver, or admin" update policy
-- had no with_check, so Postgres reused the using clause as the check —
-- letting a driver claiming a pending job rewrite unrelated columns
-- (including customer_id) as long as the resulting row satisfied any one
-- of the four using branches, and letting a customer force-assign an
-- arbitrary driver_id to their own request. Same class of bug as the
-- properties/drivers insert gaps, but a single with_check clause can't
-- express "customer_id must stay unchanged" (it only ever sees the new
-- row). Following the same narrow security-definer pattern already used
-- for update_driver_location: three functions, each touching only the
-- specific columns its actor is allowed to change, and the general
-- update policy is now admin-only.

create or replace function public.accept_moving_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_driver_id uuid;
begin
  select id into v_driver_id
  from public.drivers
  where user_id = auth.uid() and status = 'approved';

  if v_driver_id is null then
    raise exception 'not an approved driver';
  end if;

  update public.moving_requests
  set driver_id = v_driver_id,
      status = 'accepted',
      accepted_at = now()
  where id = p_request_id and status = 'pending';

  if not found then
    raise exception 'request is no longer available';
  end if;
end;
$$;

grant execute on function public.accept_moving_request(uuid) to authenticated;

create or replace function public.update_moving_request_status(
  p_request_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('in_progress', 'completed') then
    raise exception 'invalid status transition';
  end if;

  update public.moving_requests
  set status = p_status,
      completed_at = case
        when p_status = 'completed' then now()
        else completed_at
      end
  where id = p_request_id
    and driver_id in (select id from public.drivers where user_id = auth.uid());

  if not found then
    raise exception 'not your assigned request';
  end if;
end;
$$;

grant execute on function public.update_moving_request_status(uuid, text) to authenticated;

create or replace function public.cancel_moving_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.moving_requests
  set status = 'cancelled'
  where id = p_request_id and customer_id = auth.uid();

  if not found then
    raise exception 'not your request';
  end if;
end;
$$;

grant execute on function public.cancel_moving_request(uuid) to authenticated;

drop policy "Customer, claiming/assigned driver, or admin can update" on public.moving_requests;

create policy "Admins can update any moving request"
  on public.moving_requests for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));
