-- driver_repository.dart's acceptRequest()/updateStatus() call the
-- state-changing RPC, then separately insert a customer notification from
-- the client — but notifications INSERT is admin-only (drivers aren't
-- admins), so that second call always throws 42501 *after* the state
-- change already committed. The driver sees "ຮັບວຽກບໍ່ສຳເລັດ" for a job
-- they actually just accepted (and a retry then fails with "request is no
-- longer available" since it's no longer pending), while the customer
-- never receives the notification at all. Fold the notification insert
-- into the same security-definer transaction as the state change so they
-- either both happen or neither does, instead of being two independently
-- failing client calls.

create or replace function public.accept_moving_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_driver record;
  v_customer_id uuid;
begin
  select id, driver_name, vehicle_plate into v_driver
  from public.drivers
  where user_id = auth.uid() and status = 'approved';

  if v_driver.id is null then
    raise exception 'not an approved driver';
  end if;

  update public.moving_requests
  set driver_id = v_driver.id,
      status = 'accepted',
      accepted_at = now()
  where id = p_request_id and status = 'pending'
  returning customer_id into v_customer_id;

  if not found then
    raise exception 'request is no longer available';
  end if;

  insert into public.notifications (user_id, title, body, type)
  values (
    v_customer_id,
    'ຄົນຂັບຮັບຄຳຮ້ອງແລ້ວ',
    v_driver.driver_name || ' (' || v_driver.vehicle_plate || ') ຮັບຄຳຮ້ອງຂົນສົ່ງຂອງທ່ານແລ້ວ',
    'moving_accepted'
  );
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
declare
  v_customer_id uuid;
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
    and driver_id in (select id from public.drivers where user_id = auth.uid())
  returning customer_id into v_customer_id;

  if not found then
    raise exception 'not your assigned request';
  end if;

  insert into public.notifications (user_id, title, body, type)
  values (
    v_customer_id,
    case when p_status = 'completed'
      then 'ຂົນສົ່ງສຳເລັດແລ້ວ'
      else 'ຄົນຂັບກຳລັງດຳເນີນການຂົນສົ່ງ'
    end,
    case when p_status = 'completed'
      then 'ການຂົນສົ່ງຂອງທ່ານສຳເລັດແລ້ວ ຂອບໃຈທີ່ໃຊ້ບໍລິການ'
      else 'ຄົນຂັບອອກເດີນທາງໄປຮັບເຄື່ອງຂອງທ່ານແລ້ວ'
    end,
    'moving_' || p_status
  );
end;
$$;

grant execute on function public.update_moving_request_status(uuid, text) to authenticated;
