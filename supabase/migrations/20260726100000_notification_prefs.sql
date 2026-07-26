-- Per-user notification category preferences, read by the client to filter
-- what shows in the notification list and unread badge. Rows are created
-- lazily on first change — a missing row means "everything on" (the
-- column defaults below), so the client must treat no-row the same as an
-- all-true row rather than requiring an insert on first read.
create table public.notification_prefs (
  user_id uuid primary key references auth.users (id) on delete cascade,
  listing_updates boolean not null default true,
  driver_updates boolean not null default true,
  moving_updates boolean not null default true
);

alter table public.notification_prefs enable row level security;

create policy "Users can view their own notification prefs"
  on public.notification_prefs for select
  using (auth.uid() = user_id);

create policy "Users can create their own notification prefs"
  on public.notification_prefs for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own notification prefs"
  on public.notification_prefs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
