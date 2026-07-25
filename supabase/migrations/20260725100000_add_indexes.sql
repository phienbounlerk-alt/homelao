-- Foreign-key and sort-column indexes for the query patterns used by
-- property_repository.dart, booking_repository.dart, and
-- conversation_repository.dart.

create index if not exists properties_owner_id_idx on public.properties (owner_id);
create index if not exists properties_created_at_idx on public.properties (created_at desc);
create index if not exists properties_rating_idx on public.properties (rating desc);
create index if not exists properties_location_idx on public.properties (location);
create index if not exists properties_price_lak_idx on public.properties (price_lak);

create index if not exists favorites_user_id_idx on public.favorites (user_id);
create index if not exists favorites_property_id_idx on public.favorites (property_id);

create index if not exists bookings_user_id_idx on public.bookings (user_id);
create index if not exists bookings_property_id_idx on public.bookings (property_id);
create index if not exists bookings_scheduled_at_idx on public.bookings (scheduled_at desc);

create index if not exists conversations_user_id_idx on public.conversations (user_id);
create index if not exists conversations_property_id_idx on public.conversations (property_id);

create index if not exists messages_conversation_id_idx on public.messages (conversation_id);
create index if not exists messages_created_at_idx on public.messages (created_at);
