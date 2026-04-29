-- Add scroll-based earnings columns to existing creator_earnings table
ALTER TABLE public.creator_earnings
  ADD COLUMN IF NOT EXISTS series_id     uuid REFERENCES public.series(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS submission_id uuid REFERENCES public.content_submissions(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS period        date,
  ADD COLUMN IF NOT EXISTS stream_count  int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS revenue_scrolls int NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_creator_earnings_submission ON public.creator_earnings(submission_id, period);

-- Scroll-based payout requests (separate from legacy USD creator_payouts)
CREATE TABLE IF NOT EXISTS public.payout_requests (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount_scrolls int NOT NULL CHECK (amount_scrolls > 0),
  status         text NOT NULL DEFAULT 'pending',
  requested_at   timestamptz NOT NULL DEFAULT now(),
  paid_at        timestamptz
);
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payout_select_own" ON public.payout_requests FOR SELECT TO authenticated
  USING (creator_id = auth.uid());
CREATE POLICY "payout_insert_own" ON public.payout_requests FOR INSERT TO authenticated
  WITH CHECK (creator_id = auth.uid());
