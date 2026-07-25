-- The existing owner-update policy had no with_check at all, meaning an
-- owner could set their own property's status straight to 'approved' via a
-- raw API call, bypassing admin moderation entirely. Replacing it pins the
-- only status an owner's edit can produce to 'pending', so editing a
-- rejected (or any) listing always re-queues it for review instead of
-- either being blocked or silently self-approving.
drop policy "Owners can update their own properties" on public.properties;

create policy "Owners can update their own properties"
  on public.properties for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id and status = 'pending');
