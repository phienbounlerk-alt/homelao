-- analytics_events.metadata is client-supplied JSON with no shape
-- validation (any authenticated/anon caller can log a 'property_viewed'
-- event with arbitrary metadata under their own user_id). The RPC cast
-- metadata->>'property_id' straight to uuid, so a single malformed value
-- (accidental bad client build, or a deliberate junk string) crashes the
-- function with "invalid input syntax for type uuid" for every admin who
-- opens the dashboard, for as long as that row stays inside the days_back
-- window — up to 7 days by default — with no client-side way to find or
-- delete the offending row (raw analytics_events has no delete policy).
-- Filter to values that actually look like a uuid before casting, so a
-- garbage value is silently excluded from the ranking instead of taking
-- down the whole query.
create or replace function public.analytics_top_properties(days_back int default 7, max_results int default 5)
returns table (property_id uuid, view_count bigint)
language sql
stable
as $$
  select
    (metadata ->> 'property_id')::uuid as property_id,
    count(*) as view_count
  from public.analytics_events
  where event_type = 'property_viewed'
    and created_at >= now() - (days_back || ' days')::interval
    and metadata ->> 'property_id' ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  group by 1
  order by 2 desc
  limit max_results;
$$;
