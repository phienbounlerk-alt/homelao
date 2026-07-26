-- Batch 2 of the post-audit bug-fix plan: schema/data-integrity fixes.

-- 1. bookings.property_id cascaded on delete, so an owner deleting their
-- own listing silently wiped out every customer's booking history against
-- it. conversations.property_id already uses set null for the same
-- reason — bring bookings in line. property_id must become nullable for
-- set null to be legal.
alter table public.bookings
  alter column property_id drop not null;

alter table public.bookings
  drop constraint bookings_property_id_fkey;

alter table public.bookings
  add constraint bookings_property_id_fkey
  foreign key (property_id) references public.properties (id) on delete set null;

-- 2. Same fix for notifications.related_property_id (already nullable,
-- just needs the FK behavior changed).
alter table public.notifications
  drop constraint notifications_related_property_id_fkey;

alter table public.notifications
  add constraint notifications_related_property_id_fkey
  foreign key (related_property_id) references public.properties (id) on delete set null;

-- 3. Nothing stopped an owner from having two feature requests open on
-- the same property at once (a slow admin review + a retry tap creates a
-- second pending row, same double-submit shape already fixed for
-- drivers/conversations). Only one pending_review request per property
-- at a time.
create unique index featured_requests_one_pending_per_property
  on public.featured_requests (property_id)
  where status = 'pending_review';

-- 4. The moving-request RPCs guarded who could act (driver/customer
-- ownership) but not the row's current status, so a cancelled or
-- completed job could still be pushed through another transition —
-- e.g. update_moving_request_status let a driver mark an already-
-- cancelled request "completed" (cancel_moving_request never cleared
-- driver_id), silently notifying the customer their cancelled move was
-- finished. Enforce the actual state machine: pending -> accepted
-- (already guarded in accept_moving_request) -> in_progress -> completed,
-- and {pending, accepted, in_progress} -> cancelled.
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
  v_expected_current_status text;
begin
  if p_status not in ('in_progress', 'completed') then
    raise exception 'invalid status transition';
  end if;

  v_expected_current_status := case
    when p_status = 'in_progress' then 'accepted'
    when p_status = 'completed' then 'in_progress'
  end;

  update public.moving_requests
  set status = p_status,
      completed_at = case
        when p_status = 'completed' then now()
        else completed_at
      end
  where id = p_request_id
    and driver_id in (select id from public.drivers where user_id = auth.uid())
    and status = v_expected_current_status
  returning customer_id into v_customer_id;

  if not found then
    raise exception 'not your assigned request, or it is no longer in a state that allows this transition';
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

create or replace function public.cancel_moving_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.moving_requests
  set status = 'cancelled'
  where id = p_request_id
    and customer_id = auth.uid()
    and status in ('pending', 'accepted', 'in_progress');

  if not found then
    raise exception 'not your request, or it is no longer in a state that can be cancelled';
  end if;
end;
$$;

grant execute on function public.cancel_moving_request(uuid) to authenticated;
