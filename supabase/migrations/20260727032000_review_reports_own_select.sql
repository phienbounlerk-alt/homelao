-- Reporters could insert a report but not read it back — caught live
-- while testing: an INSERT ... RETURNING implicitly re-selects the row
-- under the table's SELECT policies, and review_reports only had one
-- (admins). Add read access to a reporter's own reports so the client can
-- both use RETURNING safely and show an "already reported" state.
create policy "Users can see their own reports"
  on public.review_reports for select
  using (auth.uid() = reporter_id);
