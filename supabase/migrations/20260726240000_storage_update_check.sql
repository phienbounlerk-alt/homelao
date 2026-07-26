-- "Users can update files in their own folder" had no explicit with_check,
-- relying on Postgres reusing the using clause against the new row. That
-- fallback already blocks renaming/moving a file into someone else's
-- folder (the reused check would fail against the new path), but left the
-- protection implicit rather than stated — same latent shape as the
-- profiles UPDATE gap just fixed. Storage's REST API is a curated set of
-- endpoints (upload/move/copy/remove) rather than raw PostgREST access to
-- storage.objects, so the practical exploitability here is uncertain, but
-- the RLS-level gap costs nothing to close and matches every other
-- update/insert policy in this project stating its check directly.
drop policy "Users can update files in their own folder" on storage.objects;

create policy "Users can update files in their own folder"
  on storage.objects for update
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
