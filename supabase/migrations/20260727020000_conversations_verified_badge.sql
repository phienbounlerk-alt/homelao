-- Verified Owner batch 4: surface the listing's verified flag (kept in
-- sync with the owner's approval status by sync_owner_verified_badge())
-- through the conversation list so the Messages tab and chat header can
-- show a real "ຢືນຢັນແລ້ວ" badge instead of nothing at all. Falls back to
-- false when the conversation isn't tied to a property (or it was
-- deleted), since we can't vouch for an owner we have no listing for.
drop function if exists public.conversations_with_latest_message();

create or replace function public.conversations_with_latest_message()
returns table (
  id uuid,
  landlord_name text,
  landlord_avatar_url text,
  created_at timestamptz,
  property_title text,
  property_image_url text,
  property_price_lak bigint,
  landlord_verified boolean,
  latest_message_text text,
  latest_message_created_at timestamptz
)
language sql
stable
as $$
  select
    c.id,
    c.landlord_name,
    c.landlord_avatar_url,
    c.created_at,
    p.title,
    p.image_url,
    p.price_lak,
    coalesce(p.verified, false),
    m.text,
    m.created_at
  from public.conversations c
  left join public.properties p on p.id = c.property_id
  left join lateral (
    select msg.text, msg.created_at
    from public.messages msg
    where msg.conversation_id = c.id
    order by msg.created_at desc
    limit 1
  ) m on true
  where c.user_id = auth.uid();
$$;
