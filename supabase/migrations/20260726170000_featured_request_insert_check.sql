-- The insert check only validated owner_id and property ownership, leaving
-- amount_lak, duration_days, and status client-controlled. There's no
-- tiered pricing in this app — every request is the same flat fee
-- (PaymentInstructions.amountLak/durationDays in payment_repository.dart)
-- — so a raw insert claiming a genuine 50,000 LAK proof image but
-- duration_days: 36500 would sail through admin review and grant a
-- ~100-year featured boost off a normal payment. Pinning these to the
-- one real flat-fee shape closes that without touching the app's actual
-- insert, which already sends exactly these values.
drop policy "Owners can request featuring for their own properties" on public.featured_requests;

create policy "Owners can request featuring for their own properties"
  on public.featured_requests for insert
  with check (
    auth.uid() = owner_id
    and amount_lak = 50000
    and duration_days = 7
    and status = 'pending_review'
    and exists (
      select 1 from public.properties p
      where p.id = property_id and p.owner_id = auth.uid()
    )
  );
