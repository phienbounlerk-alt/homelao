alter table public.drivers
  add column current_lat double precision,
  add column current_lng double precision,
  add column location_updated_at timestamptz;

-- A narrow, security-definer entry point for a driver to push their own
-- live position — deliberately NOT a broad "drivers can update their own
-- row" RLS policy, since that would also let a driver flip their own
-- status back to 'approved' after a rejection, bypassing admin review.
create or replace function public.update_driver_location(
  p_lat double precision,
  p_lng double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.drivers
  set current_lat = p_lat,
      current_lng = p_lng,
      location_updated_at = now()
  where user_id = auth.uid();
end;
$$;

grant execute on function public.update_driver_location(double precision, double precision) to authenticated;
