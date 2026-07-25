-- Allow clients to subscribe to live inserts on messages (RLS still applies
-- per-connection, so users only receive rows from their own conversations).
alter publication supabase_realtime add table public.messages;
