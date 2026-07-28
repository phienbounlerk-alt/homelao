-- Owner Dashboard, batch 1 of 6: schema foundation.
--
-- Adds occupancy/contact/expiry fields to properties, opens up bookings/
-- conversations/messages so a property owner can see (and, for messages,
-- participate in) activity on their own listings — none of that existed
-- before this migration, every owner-facing read was blocked by RLS — and
-- adds the aggregate RPCs the dashboard's KPI cards and charts read from.

-- ---------------------------------------------------------------------
-- properties: occupancy toggle, contact phone, listing expiry.
-- ---------------------------------------------------------------------
alter table public.properties
  add column is_rented boolean not null default false,
  add column phone_number text,
  add column expires_at timestamptz not null default (now() + interval '90 days');

-- Existing rows didn't go through the new default — give them a baseline
-- expiry relative to when they were actually posted, not "now".
update public.properties set expires_at = created_at + interval '90 days';

-- Occupancy and renewal are lightweight, frequent owner actions that
-- shouldn't force a listing back into moderation the way a content edit
-- does — the existing "Owners can update their own properties" policy
-- pins status='pending' and verified=false on every update, which is
-- correct for content changes but wrong here. Narrow, ownership-checked
-- RPCs sidestep that policy's with_check entirely, the same way
-- set_review_hidden() sidesteps reviews' column grants.
create or replace function public.toggle_property_rented(
  p_property_id uuid,
  p_is_rented boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.properties
    where id = p_property_id and owner_id = auth.uid()
  ) then
    raise exception 'not authorized';
  end if;
  update public.properties set is_rented = p_is_rented where id = p_property_id;
end;
$$;

create or replace function public.renew_property_listing(p_property_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_expiry timestamptz;
begin
  if not exists (
    select 1 from public.properties
    where id = p_property_id and owner_id = auth.uid()
  ) then
    raise exception 'not authorized';
  end if;
  v_new_expiry := now() + interval '90 days';
  update public.properties set expires_at = v_new_expiry where id = p_property_id;
  return v_new_expiry;
end;
$$;

-- ---------------------------------------------------------------------
-- messages: from_me only ever made sense from the renter's side (it's a
-- viewer-relative boolean with no stored sender) — an owner could never
-- have participated even if RLS allowed it. Add a real sender_id and
-- derive "from me" client-side by comparing it to the viewer instead.
-- ---------------------------------------------------------------------
alter table public.messages add column sender_id uuid references auth.users (id) on delete cascade;

update public.messages m
  set sender_id = c.user_id
  from public.conversations c
  where c.id = m.conversation_id;

alter table public.messages alter column sender_id set not null;

drop policy "Users can view messages in their own conversations" on public.messages;
drop policy "Users can send messages in their own conversations" on public.messages;

create policy "Renter or property owner can view conversation messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversations c
      left join public.properties p on p.id = c.property_id
      where c.id = conversation_id
        and (c.user_id = auth.uid() or p.owner_id = auth.uid())
    )
  );

create policy "Renter or property owner can send conversation messages"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      left join public.properties p on p.id = c.property_id
      where c.id = conversation_id
        and (c.user_id = auth.uid() or p.owner_id = auth.uid())
    )
  );

-- conversations: the renter-only select policy already exists; add the
-- symmetric one for the property's owner so an inbox can be built for
-- either side of the same thread.
create policy "Property owners can view conversations about their listings"
  on public.conversations for select
  using (
    exists (
      select 1 from public.properties p
      where p.id = property_id and p.owner_id = auth.uid()
    )
  );

-- bookings: renter-only select already exists; add the owner side so a
-- property owner can see who booked a viewing on their own listing.
create policy "Property owners can view bookings on their listings"
  on public.bookings for select
  using (
    exists (
      select 1 from public.properties p
      where p.id = property_id and p.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- Notification triggers — mirrors the existing security-definer pattern
-- (sync_owner_verified_badge, sync_review_helpful_count): the table
-- owner bypasses the notifications table's admin-only insert policy,
-- but only ever inserts a notification for the actual property owner
-- being acted on, computed from the row that was just inserted.
-- ---------------------------------------------------------------------
create or replace function public.notify_owner_new_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
  v_title text;
begin
  select owner_id, title into v_owner_id, v_title
    from public.properties where id = new.property_id;
  if v_owner_id is not null then
    insert into public.notifications (user_id, title, body, type, related_property_id)
    values (
      v_owner_id,
      'ມີການນັດເບິ່ງໃໝ່',
      coalesce(v_title, 'ຊັບສິນຂອງທ່ານ') || ' — ມີຄົນນັດເບິ່ງຫ້ອງໃໝ່',
      'new_booking',
      new.property_id
    );
  end if;
  return new;
end;
$$;

create trigger bookings_notify_owner
  after insert on public.bookings
  for each row execute function public.notify_owner_new_booking();

create or replace function public.notify_owner_new_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
  v_title text;
begin
  select owner_id, title into v_owner_id, v_title
    from public.properties where id = new.property_id;
  if v_owner_id is not null then
    insert into public.notifications (user_id, title, body, type, related_property_id)
    values (
      v_owner_id,
      'ມີຣີວິວໃໝ່',
      coalesce(v_title, 'ຊັບສິນຂອງທ່ານ') || ' — ໄດ້ຮັບຣີວິວໃໝ່',
      'new_review',
      new.property_id
    );
  end if;
  return new;
end;
$$;

create trigger reviews_notify_owner
  after insert on public.reviews
  for each row execute function public.notify_owner_new_review();

create or replace function public.notify_owner_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_property_id uuid;
  v_owner_id uuid;
  v_title text;
begin
  select property_id into v_property_id
    from public.conversations where id = new.conversation_id;
  if v_property_id is null then
    return new;
  end if;
  select owner_id, title into v_owner_id, v_title
    from public.properties where id = v_property_id;
  -- No owner to notify, or the owner is the one who just sent this
  -- message (their own reply shouldn't notify themself).
  if v_owner_id is null or v_owner_id = new.sender_id then
    return new;
  end if;
  insert into public.notifications (user_id, title, body, type, related_property_id)
  values (
    v_owner_id,
    'ຂໍ້ຄວາມໃໝ່',
    coalesce(v_title, 'ຊັບສິນຂອງທ່ານ') || ' — ມີຂໍ້ຄວາມໃໝ່',
    'new_message',
    v_property_id
  );
  return new;
end;
$$;

create trigger messages_notify_owner
  after insert on public.messages
  for each row execute function public.notify_owner_new_message();

-- ---------------------------------------------------------------------
-- Dashboard aggregate RPCs. Both are security definer because a
-- non-admin owner has no RLS access to raw analytics_events — the
-- function itself is the trust boundary, so every query inside is
-- explicitly scoped to properties owned by auth.uid().
-- ---------------------------------------------------------------------
create or replace function public.owner_dashboard_summary()
returns table (
  total_listings bigint,
  active_listings bigint,
  rented_listings bigint,
  occupancy_rate numeric,
  total_views bigint,
  total_favorites bigint,
  total_phone_clicks bigint,
  total_messages bigint,
  total_bookings bigint,
  avg_rating numeric,
  estimated_monthly_revenue bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid := auth.uid();
begin
  return query
  with my_properties as (
    select id, price_lak, is_rented, status
    from public.properties
    where owner_id = v_owner_id
  ),
  active as (
    select * from my_properties where status = 'approved'
  ),
  events as (
    select event_type, count(*) as c
    from public.analytics_events
    where event_type in ('property_viewed', 'favorited', 'phone_click')
      and metadata ->> 'property_id' ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and (metadata ->> 'property_id')::uuid in (select id from my_properties)
    group by event_type
  ),
  msg_count as (
    select count(*) as c
    from public.messages m
    join public.conversations conv on conv.id = m.conversation_id
    where conv.property_id in (select id from my_properties)
      and m.sender_id <> v_owner_id
  ),
  booking_count as (
    select count(*) as c
    from public.bookings b
    where b.property_id in (select id from my_properties)
  ),
  rating as (
    select avg(overall) as v
    from public.reviews r
    where r.property_id in (select id from my_properties) and r.hidden = false
  )
  select
    (select count(*) from my_properties),
    (select count(*) from active),
    (select count(*) from active where is_rented),
    case
      when (select count(*) from active) = 0 then 0
      else round(
        (select count(*) from active where is_rented)::numeric
          / (select count(*) from active) * 100,
        1
      )
    end,
    coalesce((select c from events where event_type = 'property_viewed'), 0),
    coalesce((select c from events where event_type = 'favorited'), 0),
    coalesce((select c from events where event_type = 'phone_click'), 0),
    coalesce((select c from msg_count), 0),
    coalesce((select c from booking_count), 0),
    coalesce(round((select v from rating), 1), 0),
    coalesce((select sum(price_lak) from active), 0)::bigint;
end;
$$;

create or replace function public.owner_dashboard_daily_events(p_days_back int default 365)
returns table (
  day date,
  views bigint,
  favorites bigint,
  phone_clicks bigint,
  messages bigint,
  bookings bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid := auth.uid();
begin
  return query
  with my_properties as (
    select id from public.properties where owner_id = v_owner_id
  ),
  ev as (
    select date_trunc('day', created_at)::date as day, event_type
    from public.analytics_events
    where event_type in ('property_viewed', 'favorited', 'phone_click')
      and created_at >= now() - (p_days_back || ' days')::interval
      and metadata ->> 'property_id' ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and (metadata ->> 'property_id')::uuid in (select id from my_properties)
  ),
  msg as (
    select date_trunc('day', m.created_at)::date as day
    from public.messages m
    join public.conversations conv on conv.id = m.conversation_id
    where conv.property_id in (select id from my_properties)
      and m.sender_id <> v_owner_id
      and m.created_at >= now() - (p_days_back || ' days')::interval
  ),
  bk as (
    select date_trunc('day', b.created_at)::date as day
    from public.bookings b
    where b.property_id in (select id from my_properties)
      and b.created_at >= now() - (p_days_back || ' days')::interval
  ),
  days as (
    select ev.day from ev
    union
    select msg.day from msg
    union
    select bk.day from bk
  )
  select
    d.day,
    coalesce(
      (select count(*) from ev where ev.day = d.day and ev.event_type = 'property_viewed'),
      0
    ),
    coalesce(
      (select count(*) from ev where ev.day = d.day and ev.event_type = 'favorited'),
      0
    ),
    coalesce(
      (select count(*) from ev where ev.day = d.day and ev.event_type = 'phone_click'),
      0
    ),
    coalesce((select count(*) from msg where msg.day = d.day), 0),
    coalesce((select count(*) from bk where bk.day = d.day), 0)
  from days d
  order by d.day desc;
end;
$$;
