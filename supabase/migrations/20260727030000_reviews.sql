-- Review & Rating system, batch 1: schema, trust gating, and aggregates.
--
-- "Real renter" gate: a review may only be inserted for a property the
-- reviewer has an existing booking (viewing) for — the only "you actually
-- engaged with this listing" signal this app has, enforced server-side via
-- RLS so it can't be bypassed from the client.

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  cleanliness smallint not null check (cleanliness between 1 and 5),
  location_rating smallint not null check (location_rating between 1 and 5),
  safety smallint not null check (safety between 1 and 5),
  internet smallint not null check (internet between 1 and 5),
  parking smallint not null check (parking between 1 and 5),
  value smallint not null check (value between 1 and 5),
  overall numeric(2, 1)
    generated always as (
      round(
        (cleanliness + location_rating + safety + internet + parking + value)
          / 6.0,
        1
      )
    ) stored,
  comment text not null default '',
  photos text[] not null default '{}',
  helpful_count integer not null default 0,
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (property_id, user_id)
);

create index reviews_property_id_idx on public.reviews (property_id);

alter table public.reviews enable row level security;

-- Visible to everyone once posted, except a hidden (moderated) review stays
-- visible only to its own author (so they know it was actioned) and admins.
create policy "Reviews are publicly visible unless hidden"
  on public.reviews for select
  using (
    hidden = false
    or user_id = auth.uid()
    or exists (select 1 from public.admins where user_id = auth.uid())
  );

create policy "Renters who booked a viewing can post a review"
  on public.reviews for insert
  with check (
    auth.uid() = user_id
    and hidden = false
    and helpful_count = 0
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid() and b.property_id = reviews.property_id
    )
  );

create policy "Authors can edit their own review"
  on public.reviews for update
  using (auth.uid() = user_id);

create policy "Admins can moderate any review"
  on public.reviews for update
  using (exists (select 1 from public.admins where user_id = auth.uid()));

-- A review's own author can edit the text/ratings/photos, but never the
-- moderation-owned fields — mirrors the trust-gap pattern already used for
-- owner_verifications, just via a trigger instead of with_check, since
-- with_check alone can't compare against the row's previous values.
create or replace function public.protect_review_moderation_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (select 1 from public.admins where user_id = auth.uid()) then
    return new;
  end if;
  new.helpful_count := old.helpful_count;
  new.hidden := old.hidden;
  new.updated_at := now();
  return new;
end;
$$;

create trigger reviews_protect_moderation_fields
  before update on public.reviews
  for each row
  execute function public.protect_review_moderation_fields();

-- Helpful votes: one per (review, user); a security-definer trigger keeps
-- reviews.helpful_count in sync since the voter has no update rights on
-- the reviews table itself.
create table public.review_helpful_votes (
  review_id uuid not null references public.reviews (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_id, user_id)
);

alter table public.review_helpful_votes enable row level security;

create policy "Users can see their own helpful votes"
  on public.review_helpful_votes for select
  using (auth.uid() = user_id);

create policy "Users can mark a review helpful"
  on public.review_helpful_votes for insert
  with check (auth.uid() = user_id);

create policy "Users can unmark a review helpful"
  on public.review_helpful_votes for delete
  using (auth.uid() = user_id);

create or replace function public.sync_review_helpful_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.reviews
      set helpful_count = helpful_count + 1
      where id = new.review_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.reviews
      set helpful_count = greatest(helpful_count - 1, 0)
      where id = old.review_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger review_helpful_votes_sync
  after insert or delete on public.review_helpful_votes
  for each row execute function public.sync_review_helpful_count();

-- Reports: only admins can list them (surfaced in the admin moderation
-- queue), a reporter can only see that they've reported something, one
-- report per (review, reporter) so a single user can't spam-report.
create table public.review_reports (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now(),
  unique (review_id, reporter_id)
);

alter table public.review_reports enable row level security;

create policy "Admins can view all reports"
  on public.review_reports for select
  using (exists (select 1 from public.admins where user_id = auth.uid()));

create policy "Users can report a review"
  on public.review_reports for insert
  with check (auth.uid() = reporter_id);

-- Aggregate summary (averages per category + star distribution) computed
-- server-side rather than pulling every review to the client.
create or replace function public.property_rating_summary(p_property_id uuid)
returns table (
  review_count bigint,
  avg_overall numeric,
  avg_cleanliness numeric,
  avg_location numeric,
  avg_safety numeric,
  avg_internet numeric,
  avg_parking numeric,
  avg_value numeric,
  star_1 bigint,
  star_2 bigint,
  star_3 bigint,
  star_4 bigint,
  star_5 bigint
)
language sql
stable
as $$
  select
    count(*),
    round(avg(overall), 1),
    round(avg(cleanliness), 1),
    round(avg(location_rating), 1),
    round(avg(safety), 1),
    round(avg(internet), 1),
    round(avg(parking), 1),
    round(avg(value), 1),
    count(*) filter (where round(overall) = 1),
    count(*) filter (where round(overall) = 2),
    count(*) filter (where round(overall) = 3),
    count(*) filter (where round(overall) = 4),
    count(*) filter (where round(overall) = 5)
  from public.reviews
  where property_id = p_property_id and hidden = false;
$$;

-- Admin queue: reviews with at least one report, newest report first.
create or replace function public.reported_reviews()
returns table (
  review_id uuid,
  property_id uuid,
  property_title text,
  user_id uuid,
  comment text,
  overall numeric,
  hidden boolean,
  report_count bigint,
  latest_report_at timestamptz,
  latest_report_reason text
)
language sql
stable
as $$
  select
    r.id,
    r.property_id,
    p.title,
    r.user_id,
    r.comment,
    r.overall,
    r.hidden,
    count(rr.id),
    max(rr.created_at),
    (array_agg(rr.reason order by rr.created_at desc))[1]
  from public.reviews r
  join public.review_reports rr on rr.review_id = r.id
  left join public.properties p on p.id = r.property_id
  where exists (select 1 from public.admins where user_id = auth.uid())
  group by r.id, p.title
  order by max(rr.created_at) desc;
$$;
