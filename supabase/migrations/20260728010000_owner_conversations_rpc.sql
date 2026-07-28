-- Owner Dashboard, batch 5: owner-side conversation list.
--
-- Mirrors conversations_with_latest_message() (invoker-scoped, relies on
-- the same RLS this session already opened up for owners in Batch 1) but
-- keyed off property ownership instead of c.user_id, and returns the
-- renter's identity instead of the landlord's.
create or replace function public.owner_conversations_with_latest_message()
returns table (
  id uuid,
  renter_name text,
  renter_avatar_url text,
  created_at timestamptz,
  property_id uuid,
  property_title text,
  property_image_url text,
  property_price_lak bigint,
  latest_message_text text,
  latest_message_created_at timestamptz
)
language sql
stable
as $$
  select
    c.id,
    coalesce(pr.name, 'ຜູ້ໃຊ້'),
    pr.avatar_url,
    c.created_at,
    p.id,
    p.title,
    p.image_url,
    p.price_lak,
    m.text,
    m.created_at
  from public.conversations c
  join public.properties p on p.id = c.property_id
  left join public.profiles pr on pr.id = c.user_id
  left join lateral (
    select msg.text, msg.created_at
    from public.messages msg
    where msg.conversation_id = c.id
    order by msg.created_at desc
    limit 1
  ) m on true
  where p.owner_id = auth.uid();
$$;
