-- Batch 2 prep: point reviews.user_id at public.profiles instead of
-- auth.users so the repository can embed the reviewer's name/avatar in a
-- single PostgREST query (reviews(*, profiles(name, avatar_url))) rather
-- than a second round-trip. Every auth user already gets a profiles row
-- via handle_new_user(), and profiles.id itself cascades from auth.users,
-- so the delete-cascade chain is unchanged.
alter table public.reviews
  drop constraint reviews_user_id_fkey,
  add constraint reviews_user_id_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;
