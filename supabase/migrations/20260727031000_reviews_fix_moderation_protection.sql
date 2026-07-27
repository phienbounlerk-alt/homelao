-- Batch 1 follow-up fix: the BEFORE UPDATE trigger added to protect
-- helpful_count/hidden from owner tampering also fired on the security
-- definer helpful-vote-sync trigger's own UPDATE, silently undoing the
-- increment it had just made (caught live while testing the helpful-vote
-- flow — see conversation). Column-level grants don't have this recursion
-- problem, so switch to that instead: owners can only ever UPDATE the
-- columns a review edit is meant to touch; hidden is now only reachable
-- through a dedicated admin-checked function, never a raw table UPDATE.

drop trigger if exists reviews_protect_moderation_fields on public.reviews;
drop function if exists public.protect_review_moderation_fields();
drop policy if exists "Admins can moderate any review" on public.reviews;

revoke update on public.reviews from authenticated;
grant update (
  cleanliness, location_rating, safety, internet, parking, value,
  comment, photos, updated_at
) on public.reviews to authenticated;

create or replace function public.set_review_hidden(
  p_review_id uuid,
  p_hidden boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.admins where user_id = auth.uid()) then
    raise exception 'not authorized';
  end if;
  update public.reviews
    set hidden = p_hidden, updated_at = now()
    where id = p_review_id;
end;
$$;
