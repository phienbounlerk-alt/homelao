-- Public bucket for property listing photos and profile avatars.
-- Objects are stored under `{auth.uid()}/{filename}` so RLS can scope
-- write access to the uploading user's own folder.
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

create policy "Photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'photos');

create policy "Users can upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update files in their own folder"
  on storage.objects for update
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete files in their own folder"
  on storage.objects for delete
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
