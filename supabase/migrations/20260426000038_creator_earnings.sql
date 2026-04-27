ALTER TABLE public.creator_profiles ADD COLUMN IF NOT EXISTS stripe_account_id TEXT;

-- creator_earnings: per-episode daily revenue snapshots
CREATE TABLE IF NOT EXISTS public.creator_earnings (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id                UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  episode_id                UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  date                      DATE NOT NULL,
  energy_gate_revenue_usd   NUMERIC(10,4) NOT NULL DEFAULT 0,
  subscription_share_usd    NUMERIC(10,4) NOT NULL DEFAULT 0,
  UNIQUE (creator_id, episode_id, date)
);
ALTER TABLE public.creator_earnings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "earnings_select_own" ON public.creator_earnings
  FOR SELECT USING (auth.uid() = creator_id);
CREATE INDEX IF NOT EXISTS creator_earnings_creator_idx ON public.creator_earnings(creator_id);
CREATE INDEX IF NOT EXISTS creator_earnings_date_idx ON public.creator_earnings(date DESC);

-- creator_payouts: monthly payout records
CREATE TABLE IF NOT EXISTS public.creator_payouts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_start        DATE NOT NULL,
  period_end          DATE NOT NULL,
  amount_usd          NUMERIC(10,2) NOT NULL,
  status              TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','paid','failed')),
  stripe_transfer_id  TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.creator_payouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payouts_select_own" ON public.creator_payouts
  FOR SELECT USING (auth.uid() = creator_id);
CREATE INDEX IF NOT EXISTS creator_payouts_creator_idx ON public.creator_payouts(creator_id);
