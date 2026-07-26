-- DriverRepository.fetchMine() assumes at most one driver row per user
-- (.maybeSingle()), but nothing enforced that — a double-submitted
-- registration (retry after a slow network response, browser back/forward
-- resubmit) could silently create a second row. From then on fetchMine()
-- throws a PostgrestException on every call, permanently breaking the
-- driver profile screen, fetchMyJobs(), and acceptRequest() for that user
-- with no in-app recovery path. The registration form already guards
-- against a double-tap (disables the button while submitting) and shows
-- a normal "failed, try again" snackbar on any insert error, so a
-- constraint violation here degrades gracefully instead of corrupting
-- state.
alter table public.drivers
  add constraint drivers_user_id_key unique (user_id);
