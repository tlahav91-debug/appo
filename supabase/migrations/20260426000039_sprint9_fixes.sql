-- Add creator_id to episodes for direct creator lookup (fixes PRD-046 creator attribution)
ALTER TABLE public.episodes ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Add UNIQUE constraint to creator_payouts to prevent duplicate payout rows (PRD-046-03)
ALTER TABLE public.creator_payouts
  ADD CONSTRAINT creator_payouts_period_unique UNIQUE (creator_id, period_start, period_end);

-- Atomic energy revenue increment RPC (PRD-046-01)
CREATE OR REPLACE FUNCTION increment_energy_revenue(
  p_creator_id UUID,
  p_episode_id UUID,
  p_date       DATE,
  p_amount     NUMERIC
) RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  INSERT INTO public.creator_earnings (creator_id, episode_id, date, energy_gate_revenue_usd)
  VALUES (p_creator_id, p_episode_id, p_date, p_amount)
  ON CONFLICT (creator_id, episode_id, date)
  DO UPDATE SET energy_gate_revenue_usd =
    public.creator_earnings.energy_gate_revenue_usd + EXCLUDED.energy_gate_revenue_usd;
$$;
REVOKE EXECUTE ON FUNCTION increment_energy_revenue FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_energy_revenue TO service_role;
