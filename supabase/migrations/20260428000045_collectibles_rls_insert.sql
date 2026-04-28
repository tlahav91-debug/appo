-- Migration: add service_role INSERT policy + earned_at on user_collectibles
-- PRD-055: Collectible Card Album

ALTER TABLE public.user_collectibles
  ADD COLUMN IF NOT EXISTS earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE POLICY "service_role can mint collectibles"
  ON public.user_collectibles FOR INSERT
  WITH CHECK (auth.role() = 'service_role');
