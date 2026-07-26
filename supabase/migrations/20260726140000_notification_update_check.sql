-- The update policy only pinned user_id via using (checked against the OLD
-- row), with no with_check — so Postgres never validated the NEW row,
-- leaving every column writable including user_id itself. Any user with
-- one notification of their own (trivial to get — post a listing) could
-- retarget it to another user_id, injecting a fabricated notification
-- straight into a stranger's realtime feed and fully defeating the
-- admin-only insert policy. The app only ever flips `read` to true
-- (NotificationRepository.markRead/markAllRead), so pinning user_id
-- unchanged doesn't affect any legitimate flow.
drop policy "Users can mark their own notifications read" on public.notifications;

create policy "Users can mark their own notifications read"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
