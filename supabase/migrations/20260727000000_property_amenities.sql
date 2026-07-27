-- Backs the new AI-assisted search's "parking" / "pet-friendly" filters —
-- neither existed under any name before this. Existing listings default to
-- false until their owner sets them via the post-listing form.
alter table public.properties
  add column parking boolean not null default false,
  add column pet_friendly boolean not null default false;
