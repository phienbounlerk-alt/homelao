-- "Users can update their own profile" had no explicit with_check, relying
-- on Postgres reusing the using clause against the new row — which does
-- already block reassigning id to someone else's row, but leaves that
-- protection implicit rather than stated. Add it explicitly for the same
-- reason every other update/insert policy in this project states its
-- check directly, rather than depending on Postgres's fallback behavior.
--
-- Note: public.profiles is not currently read from or written to by the
-- app (profile name/avatar are stored in auth.users user_metadata
-- instead) — this table is only ever populated by the on_auth_user_created
-- trigger. So there's no real client-reachable exploit here today, but the
-- gap is closed anyway to match the rest of the schema's pattern.
drop policy "Users can update their own profile" on public.profiles;

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
