-- [SCHEMA] Energy system integrity fixes — BUG-001, BUG-002, BUG-003

-- BUG-003: Hard floor on gems balance
ALTER TABLE public.profiles
  ADD CONSTRAINT chk_gems_non_negative CHECK (gems >= 0);

-- BUG-001: Atomic ad reward claim using FOR UPDATE row lock to prevent
-- concurrent requests bypassing the 5-ad daily cap.
CREATE OR REPLACE FUNCTION public.claim_ad_reward(
  p_user_id    UUID,
  p_reward_type TEXT  -- 'energy' | 'coins'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count        INT;
  v_profile      RECORD;
  v_new_energy   INT;
  v_new_coins    INT;
  v_hours        INT;
  v_refilled     INT;
  v_idem_key     TEXT;
  v_reward_amount INT;
  v_new_last_refill TIMESTAMPTZ;
BEGIN
  -- Lock the profile row — serialises concurrent requests for this user
  SELECT current_energy, last_refill_at, coins
  INTO v_profile
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'PROFILE_NOT_FOUND');
  END IF;

  -- Count today's ad views (inside the lock scope)
  SELECT COUNT(*) INTO v_count
  FROM public.ad_views
  WHERE user_id = p_user_id
    AND viewed_at >= CURRENT_DATE::TIMESTAMPTZ;

  IF v_count >= 5 THEN
    RETURN jsonb_build_object(
      'error', 'AD_CAP_REACHED',
      'views_today', v_count
    );
  END IF;

  -- Lazy energy refill
  v_hours    := FLOOR(EXTRACT(EPOCH FROM (NOW() - v_profile.last_refill_at)) / 3600)::INT;
  v_refilled := LEAST(20, v_profile.current_energy + v_hours);

  -- Insert ad view record
  INSERT INTO public.ad_views (user_id, reward_type, reward_amount)
  VALUES (p_user_id, p_reward_type,
    CASE WHEN p_reward_type = 'energy' THEN 2 ELSE 50 END);

  IF p_reward_type = 'energy' THEN
    v_reward_amount := 2;
    v_new_energy    := LEAST(20, v_refilled + v_reward_amount);
    v_new_last_refill := CASE WHEN v_new_energy = 20 THEN NOW()
                              ELSE v_profile.last_refill_at + (v_hours || ' hours')::INTERVAL
                         END;

    UPDATE public.profiles
    SET current_energy = v_new_energy,
        last_refill_at = v_new_last_refill
    WHERE id = p_user_id;

    INSERT INTO public.energy_log (user_id, delta, balance_after, reason)
    VALUES (p_user_id, v_reward_amount, v_new_energy, 'ad_reward');

    RETURN jsonb_build_object(
      'reward_type',      'energy',
      'reward_amount',    v_reward_amount,
      'energy_remaining', v_new_energy,
      'ad_views_today',   v_count + 1
    );
  ELSE
    v_reward_amount := 50;
    v_new_coins     := v_profile.coins + v_reward_amount;
    v_idem_key      := 'ad_reward_' || p_user_id || '_' || CURRENT_DATE || '_' || (v_count + 1);

    UPDATE public.profiles
    SET coins = v_new_coins
    WHERE id = p_user_id;

    INSERT INTO public.currency_ledger
      (user_id, currency_type, delta, balance_after, reason, idempotency_key)
    VALUES
      (p_user_id, 'scrolls', v_reward_amount, v_new_coins, 'ad_reward', v_idem_key);

    RETURN jsonb_build_object(
      'reward_type',      'coins',
      'reward_amount',    v_reward_amount,
      'energy_remaining', v_refilled,
      'ad_views_today',   v_count + 1
    );
  END IF;
END;
$$;
