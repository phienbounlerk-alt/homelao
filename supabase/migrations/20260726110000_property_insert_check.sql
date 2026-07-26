-- The original insert policy only pinned owner_id, so a raw REST call
-- could set status/featured/rating/views directly on creation and bypass
-- moderation entirely — the same gap already closed on the update policy
-- (see 20260726090000_property_resubmit.sql), just missed on insert. The
-- app itself never sends these columns on insert (they're meant to start
-- at their table defaults), so this doesn't change any legitimate flow.
drop policy "Owners can insert their own properties" on public.properties;

create policy "Owners can insert their own properties"
  on public.properties for insert
  with check (
    auth.uid() = owner_id
    and status = 'pending'
    and featured = false
    and featured_until is null
    and rating = 0
    and views = 0
  );
