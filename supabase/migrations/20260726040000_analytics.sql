create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  event_type text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.analytics_events enable row level security;

-- A caller may only ever log an event as themselves (or anonymously with
-- user_id null) — never spoof another user's id.
create policy "Anyone can log their own analytics events"
  on public.analytics_events for insert
  with check (user_id is null or user_id = auth.uid());

-- Raw events are only ever readable by admins; everyone else only writes.
create policy "Admins can view analytics events"
  on public.analytics_events for select
  using (exists (select 1 from public.admins where user_id = auth.uid()));

create index analytics_events_type_created_idx
  on public.analytics_events (event_type, created_at desc);
create index analytics_events_created_idx
  on public.analytics_events (created_at desc);

-- All three RPCs below are security invoker (the default) — they read
-- from analytics_events under the caller's own RLS, so a non-admin caller
-- transparently gets back zero rows rather than needing a separate check.

create or replace function public.analytics_daily_counts(days_back int default 14)
returns table (day date, event_count bigint, distinct_users bigint)
language sql
stable
as $$
  select
    date_trunc('day', created_at)::date as day,
    count(*) as event_count,
    count(distinct user_id) as distinct_users
  from public.analytics_events
  where created_at >= now() - (days_back || ' days')::interval
  group by 1
  order by 1 desc;
$$;

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
    and metadata ->> 'property_id' is not null
  group by 1
  order by 2 desc
  limit max_results;
$$;

create or replace function public.analytics_top_searches(days_back int default 7, max_results int default 5)
returns table (query text, search_count bigint)
language sql
stable
as $$
  select
    metadata ->> 'query' as query,
    count(*) as search_count
  from public.analytics_events
  where event_type = 'search_performed'
    and created_at >= now() - (days_back || ' days')::interval
    and coalesce(metadata ->> 'query', '') <> ''
  group by 1
  order by 2 desc
  limit max_results;
$$;
