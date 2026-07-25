-- Profiles: one row per authenticated user, created on signup.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Properties: listings, owned by the landlord who posted them.
create table public.properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete set null,
  image_url text not null,
  price_lak bigint not null,
  title text not null,
  location text not null,
  beds int not null default 0,
  baths int not null default 0,
  area_sqm int not null default 0,
  rating numeric(2, 1) not null default 0,
  views int not null default 0,
  verified boolean not null default true,
  landlord_name text not null default '',
  landlord_avatar_url text,
  description text not null default '',
  created_at timestamptz not null default now()
);

alter table public.properties enable row level security;

create policy "Properties are viewable by everyone"
  on public.properties for select
  using (true);

create policy "Owners can insert their own properties"
  on public.properties for insert
  with check (auth.uid() = owner_id);

create policy "Owners can update their own properties"
  on public.properties for update
  using (auth.uid() = owner_id);

create policy "Owners can delete their own properties"
  on public.properties for delete
  using (auth.uid() = owner_id);

-- Favorites: which listings a user has bookmarked.
create table public.favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, property_id)
);

alter table public.favorites enable row level security;

create policy "Users can view their own favorites"
  on public.favorites for select
  using (auth.uid() = user_id);

create policy "Users can add their own favorites"
  on public.favorites for insert
  with check (auth.uid() = user_id);

create policy "Users can remove their own favorites"
  on public.favorites for delete
  using (auth.uid() = user_id);

-- Conversations: one thread per (user, property) chat with a landlord.
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  property_id uuid references public.properties (id) on delete set null,
  landlord_name text not null,
  landlord_avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.conversations enable row level security;

create policy "Users can view their own conversations"
  on public.conversations for select
  using (auth.uid() = user_id);

create policy "Users can create their own conversations"
  on public.conversations for insert
  with check (auth.uid() = user_id);

-- Messages: chat bubbles within a conversation.
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  from_me boolean not null,
  text text not null,
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "Users can view messages in their own conversations"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );

create policy "Users can send messages in their own conversations"
  on public.messages for insert
  with check (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );

-- Bookings: scheduled viewing appointments.
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  scheduled_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.bookings enable row level security;

create policy "Users can view their own bookings"
  on public.bookings for select
  using (auth.uid() = user_id);

create policy "Users can create their own bookings"
  on public.bookings for insert
  with check (auth.uid() = user_id);
