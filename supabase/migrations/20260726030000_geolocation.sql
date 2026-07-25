alter table public.properties add column lat double precision;
alter table public.properties add column lng double precision;

create index properties_lat_lng_idx
  on public.properties (lat, lng)
  where lat is not null and lng is not null;

-- Distance (Haversine, km) from an origin point to every geotagged property,
-- limited to those within radius_km. security invoker (the default) means
-- this still respects the caller's RLS on properties — a non-admin caller
-- never sees another owner's pending/rejected rows through this function
-- either.
create or replace function public.properties_near(
  origin_lat double precision,
  origin_lng double precision,
  radius_km double precision default 15,
  max_results int default 30
)
returns table (id uuid, distance_km double precision)
language sql
stable
as $$
  with distances as (
    select
      p.id,
      6371 * acos(
        least(1, greatest(-1,
          cos(radians(origin_lat)) * cos(radians(p.lat)) *
          cos(radians(p.lng) - radians(origin_lng)) +
          sin(radians(origin_lat)) * sin(radians(p.lat))
        ))
      ) as distance_km
    from public.properties p
    where p.lat is not null and p.lng is not null
  )
  select id, distance_km
  from distances
  where distance_km <= radius_km
  order by distance_km asc
  limit max_results;
$$;
