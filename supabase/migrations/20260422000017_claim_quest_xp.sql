-- PRD-015: Wire XP grant into claim_quest_reward (inline, same transaction as reward)
CREATE OR REPLACE FUNCTION public.claim_quest_reward(
  p_user_id  UUID,
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
  v_xp_result JSONB;
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

  SELECT completed_at, reward_claimed_at
  INTO v_completed, v_claimed
  FROM public.user_quest_progress
  WHERE user_id = p_user_id AND quest_id = p_quest_id
  FOR UPDATE;

  IF v_completed IS NULL THEN
    RETURN jsonb_build_object('error', 'Quest not completed', 'code', 403);
  END IF;

  -- Idempotent: already claimed — return without re-granting XP
  IF v_claimed IS NOT NULL THEN
    RETURN jsonb_build_object(
      'gems_earned',   v_gems,
      'coins_earned',  v_coins,
      'xp_gained',     0,
      'leveled_up',    FALSE,
      'idempotent',    TRUE
    );
  END IF;

  SELECT gems, coins INTO v_cur_gems, v_cur_coins
  FROM public.profiles WHERE id = p_user_id;

  v_new_gems  := v_cur_gems + v_gems;
  v_new_coins := v_cur_coins + v_coins;
  v_tx_id     := 'quest_' || p_quest_id::TEXT || '_' || p_user_id::TEXT;

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

  -- Grant XP in the same transaction; grant_xp issues its own UPDATE on profiles
  v_xp_result := public.grant_xp(p_user_id, 50, 'lava_quest');

  RETURN jsonb_build_object(
    'gems_earned',   v_gems,
    'coins_earned',  v_coins,
    'xp_gained',     50,
    'leveled_up',    COALESCE((v_xp_result->>'leveled_up')::BOOLEAN, FALSE),
    'new_fan_level', COALESCE((v_xp_result->>'new_fan_level')::INTEGER, 1)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.claim_quest_reward(UUID, UUID) TO service_role;
