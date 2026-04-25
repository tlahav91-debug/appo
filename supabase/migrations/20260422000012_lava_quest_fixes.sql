-- BUG-002: Grant EXECUTE to service_role so edge functions can call the RPC
GRANT EXECUTE ON FUNCTION public.increment_quest_progress(UUID, UUID) TO service_role;

-- BUG-004: Guard against incrementing progress on already-completed quests
CREATE OR REPLACE FUNCTION public.increment_quest_progress(
  p_user_id   UUID,
  p_series_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_quest_id UUID;
  v_goal     SMALLINT;
BEGIN
  SELECT id, goal_value INTO v_quest_id, v_goal
  FROM public.lava_quests
  WHERE series_id = p_series_id
    AND is_active = TRUE
    AND starts_at <= NOW()
    AND ends_at > NOW()
  LIMIT 1;

  IF v_quest_id IS NULL THEN
    RETURN;
  END IF;

  -- Skip if already completed
  IF EXISTS (
    SELECT 1 FROM public.user_quest_progress
    WHERE user_id = p_user_id AND quest_id = v_quest_id AND completed_at IS NOT NULL
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.user_quest_progress (user_id, quest_id, progress)
  VALUES (p_user_id, v_quest_id, 1)
  ON CONFLICT (user_id, quest_id) DO UPDATE
    SET progress = LEAST(public.user_quest_progress.progress + 1, v_goal);

  -- Mark completed when goal reached
  UPDATE public.user_quest_progress
  SET completed_at = NOW()
  WHERE user_id = p_user_id
    AND quest_id = v_quest_id
    AND progress >= v_goal
    AND completed_at IS NULL;
END;
$$;

-- BUG-001: Atomic claim RPC — replaces non-atomic edge function credit logic
CREATE OR REPLACE FUNCTION public.claim_quest_reward(
  p_user_id UUID,
  p_quest_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_gems      SMALLINT;
  v_coins     SMALLINT;
  v_ends_at   TIMESTAMPTZ;
  v_is_active BOOLEAN;
  v_completed TIMESTAMPTZ;
  v_claimed   TIMESTAMPTZ;
  v_cur_gems  INT;
  v_cur_coins INT;
  v_new_gems  INT;
  v_new_coins INT;
  v_tx_id     TEXT;
BEGIN
  SELECT reward_gems, reward_coins, ends_at, is_active
  INTO v_gems, v_coins, v_ends_at, v_is_active
  FROM public.lava_quests WHERE id = p_quest_id;

  IF NOT FOUND OR NOT v_is_active THEN
    RETURN jsonb_build_object('error', 'Quest not found', 'code', 404);
  END IF;

  IF v_ends_at <= NOW() THEN
    RETURN jsonb_build_object('error', 'Quest expired', 'code', 410);
  END IF;

  -- Row-level lock prevents concurrent double-claim
  SELECT completed_at, reward_claimed_at
  INTO v_completed, v_claimed
  FROM public.user_quest_progress
  WHERE user_id = p_user_id AND quest_id = p_quest_id
  FOR UPDATE;

  IF v_completed IS NULL THEN
    RETURN jsonb_build_object('error', 'Quest not completed', 'code', 403);
  END IF;

  IF v_claimed IS NOT NULL THEN
    RETURN jsonb_build_object('gems_earned', v_gems, 'coins_earned', v_coins, 'idempotent', TRUE);
  END IF;

  SELECT gems, coins INTO v_cur_gems, v_cur_coins
  FROM public.profiles WHERE id = p_user_id;

  v_new_gems  := v_cur_gems + v_gems;
  v_new_coins := v_cur_coins + v_coins;
  v_tx_id     := 'quest_' || p_quest_id::TEXT || '_' || p_user_id::TEXT;

  -- Ledger rows (idempotency_key unique guard handles any retry)
  INSERT INTO public.currency_ledger
    (user_id, currency_type, delta, balance_after, reason, idempotency_key, reference_id)
  VALUES
    (p_user_id, 'gems',    v_gems,  v_new_gems,  'quest_reward', v_tx_id || '_gems',  p_quest_id),
    (p_user_id, 'scrolls', v_coins, v_new_coins, 'quest_reward', v_tx_id || '_coins', p_quest_id)
  ON CONFLICT (idempotency_key) DO NOTHING;

  UPDATE public.profiles
  SET gems = v_new_gems, coins = v_new_coins
  WHERE id = p_user_id;

  UPDATE public.user_quest_progress
  SET reward_claimed_at = NOW()
  WHERE user_id = p_user_id AND quest_id = p_quest_id;

  RETURN jsonb_build_object('gems_earned', v_gems, 'coins_earned', v_coins);
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_quest_reward(UUID, UUID) TO service_role;
