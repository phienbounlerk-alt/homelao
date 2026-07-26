-- ConversationRepository.findOrCreate() does a select-then-insert with no
-- transaction/locking between the two, and nothing enforced at most one
-- conversation per (user_id, property_id). Two near-simultaneous "chat
-- with landlord" taps (or a double-fire from a slow network) can both
-- pass the select check before either insert lands, creating two rows —
-- after which findOrCreate()'s own select throws for that property, and
-- the user's messages end up split across two threads.
alter table public.conversations
  add constraint conversations_user_property_key unique (user_id, property_id);
