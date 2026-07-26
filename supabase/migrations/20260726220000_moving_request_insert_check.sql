-- "Customers can create their own moving request" only checked
-- customer_id = auth.uid(), leaving driver_id/status/accepted_at/
-- completed_at free — a customer could insert a request that already
-- points at an arbitrary driver_id with status 'accepted' (or even
-- 'completed'), injecting a fabricated already-accepted job straight
-- into that driver's job list without the driver ever having claimed
-- it. Pin every column the client shouldn't be able to set at creation
-- time, same as the properties/drivers insert fixes.
drop policy "Customers can create their own moving request" on public.moving_requests;

create policy "Customers can create their own moving request"
  on public.moving_requests for insert
  with check (
    customer_id = auth.uid()
    and status = 'pending'
    and driver_id is null
    and accepted_at is null
    and completed_at is null
  );
