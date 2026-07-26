-- Same gap as the property insert policy (see 20260726110000): the
-- original insert check only pinned user_id, so a raw REST call could set
-- status: 'approved' directly at registration and skip admin moderation
-- entirely. The app itself never sends status on insert (DriverRepository
-- .register), so this doesn't change any legitimate flow.
drop policy "Users can register as a driver" on public.drivers;

create policy "Users can register as a driver"
  on public.drivers for insert
  with check (user_id = auth.uid() and status = 'pending');
