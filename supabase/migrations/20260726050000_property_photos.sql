alter table public.properties add column photos text[] not null default '{}';

-- Backfill existing listings so they still show their one photo in the
-- new gallery instead of an empty array.
update public.properties
set photos = array[image_url]
where photos = '{}';
