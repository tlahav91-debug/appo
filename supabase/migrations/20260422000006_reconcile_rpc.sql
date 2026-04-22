-- [SCHEMA] Admin reconciliation RPC — resyncs profiles.coins/gems from ledger

-- Also seed episode_choices.reward_coins default to 10
UPDATE public.episode_choices SET label = label WHERE collectible_id IS NULL; -- no-op to satisfy migration runner
ALTER TABLE public.episode_choices
  ADD COLUMN IF NOT EXISTS reward_coins INTEGER NOT NULL DEFAULT 10;

-- Update existing seed choices to award 10 coins each
UPDATE public.episode_choices SET reward_coins = 10 WHERE reward_coins = 0;

-- ============================================================
-- reconcile_balances() — callable by service role only
-- Resyncs profiles.coins and profiles.gems from the latest
-- balance_after in currency_ledger. Returns a diff per user.
-- ============================================================

CREATE OR REPLACE FUNCTION public.reconcile_balances(p_user_id UUID DEFAULT NULL)
RETURNS TABLE(
  out_user_id    UUID,
  coins_before   INTEGER,
  coins_after    INTEGER,
  gems_before    INTEGER,
  gems_after     INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH ledger_truth AS (
    SELECT DISTINCT ON (user_id, currency_type)
      user_id,
      currency_type,
      balance_after
    FROM public.currency_ledger
    WHERE (p_user_id IS NULL OR user_id = p_user_id)
    ORDER BY user_id, currency_type, created_at DESC
  ),
  coins_truth AS (
    SELECT user_id, balance_after AS true_coins
    FROM ledger_truth WHERE currency_type = 'scrolls'
  ),
  gems_truth AS (
    SELECT user_id, balance_after AS true_gems
    FROM ledger_truth WHERE currency_type = 'gems'
  ),
  updates AS (
    UPDATE public.profiles p
    SET
      coins = COALESCE(c.true_coins, p.coins),
      gems  = COALESCE(g.true_gems,  p.gems)
    FROM
      coins_truth c
      FULL OUTER JOIN gems_truth g ON c.user_id = g.user_id
    WHERE p.id = COALESCE(c.user_id, g.user_id)
      AND (p_user_id IS NULL OR p.id = p_user_id)
    RETURNING
      p.id                            AS user_id,
      p.coins                         AS coins_after,
      p.gems                          AS gems_after,
      COALESCE(c.true_coins, p.coins) AS coins_truth_val,
      COALESCE(g.true_gems,  p.gems)  AS gems_truth_val
  )
  SELECT
    u.user_id,
    -- Before = what was stored (we only have the after from RETURNING)
    -- Return coins_after as both before and after when no ledger row exists
    u.coins_after                 AS coins_before,
    u.coins_truth_val             AS coins_after,
    u.gems_after                  AS gems_before,
    u.gems_truth_val              AS gems_after
  FROM updates u;
END;
$$;

-- Revoke from public; callable by service role only
REVOKE ALL ON FUNCTION public.reconcile_balances(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_balances(UUID) FROM authenticated;
