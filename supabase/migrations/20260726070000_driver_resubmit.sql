-- A rejected driver can edit and resubmit their own registration instead of
-- being stuck with no way to try again. The with-check pins the only status
-- transition they can make to 'pending', so they can't self-approve.
create policy "Users can resubmit a rejected driver registration"
  on public.drivers for update
  using (user_id = auth.uid() and status = 'rejected')
  with check (user_id = auth.uid() and status = 'pending');
