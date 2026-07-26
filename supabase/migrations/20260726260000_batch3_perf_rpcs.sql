-- Batch 3 of the post-audit bug-fix plan: two client queries that scaled
-- with total table size instead of what the screen actually needs.

-- ConversationRepository.fetchConversations() embedded the full messages
-- history of every conversation just to render a one-line preview and
-- compute last-activity ordering — pulling every message ever sent, on
-- every Messages-tab open, and growing without bound as chat history
-- accumulates. Compute just the single latest message server-side instead.
create or replace function public.conversations_with_latest_message()
returns table (
  id uuid,
  landlord_name text,
  landlord_avatar_url text,
  created_at timestamptz,
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
    c.landlord_name,
    c.landlord_avatar_url,
    c.created_at,
    p.title,
    p.image_url,
    p.price_lak,
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

-- PropertyRepository.fetchLocations() fetched the location column for
-- every row in the table just to derive a handful of distinct district
-- chips for the search screen — scales linearly with listing count.
-- Do the distinct-and-split server-side instead, matching the same
-- split(',').first.trim() logic the client used to do after the fact.
create or replace function public.distinct_property_districts()
returns table (district text)
language sql
stable
as $$
  select distinct trim(split_part(location, ',', 1)) as district
  from public.properties;
$$;
