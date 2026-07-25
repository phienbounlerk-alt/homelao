-- Per-user notifications (listing approved/rejected, feature request
-- reviewed, etc.), delivered live via Supabase Realtime the same way chat
-- messages already are.
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  related_property_id uuid references public.properties (id) on delete cascade,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can mark their own notifications read"
  on public.notifications for update
  using (auth.uid() = user_id);

-- Only admins can create a notification for someone else (e.g. moderation
-- outcomes) — there's no general "notify any user" path from the client.
create policy "Admins can create notifications for any user"
  on public.notifications for insert
  with check (exists (select 1 from public.admins where user_id = auth.uid()));

alter publication supabase_realtime add table public.notifications;

create index notifications_user_id_created_at_idx
  on public.notifications (user_id, created_at desc);
