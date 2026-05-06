-- PRD-097: Separate energy/coin ad caps; fix payouts (energy: +5, coins: +15)
-- ad_views.reward_type column already exists — no ADD COLUMN needed.
-- Replace the RPC to enforce per-type daily caps and corrected reward amounts.

DROP FUNCTION IF EXISTS public.claim_ad_reward(uuid, text);

CREATE OR REPLACE FUNCTION public.claim_ad_reward(
  p_user_id     UUID,
  p_reward_type TEXT  -- 'energy' | 'coins'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cap           INT;
  v_count         INT;
  v_reward_amount INT;
  v_profile       RECORD;
  v_new_energy    INT;
  v_new_coins     INT;
  v_hours         INT;
  v_refilled      INT;
  v_new_last_refill TIMESTAMPTZ;
  v_idem_key      TEXT;
BEGIN
  -- Per-type daily cap: energy = 3/day, coins = 2/day
  v_cap := CASE WHEN p_reward_type = 'energy' THEN 3 ELSE 2 END;

  -- Per-type reward payout: energy = +5⚡, coins = +15🪙
  v_reward_amount := CASE WHEN p_reward_type = 'energy' THEN 5 ELSE 15 END;

  -- Lock profile row — serialises concurrent requests for this user
  SELECT current_energy, last_refill_at, coins
  INTO v_profile
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'PROFILE_NOT_FOUND');
  END IF;

  -- Count today's views for THIS reward type only (independent caps)
  SELECT COUNT(*) INTO v_count
  FROM public.ad_views
  WHERE user_id    = p_user_id
    AND reward_type = p_reward_type
    AND viewed_at  >= CURRENT_DATE::TIMESTAMPTZ;

  IF v_count >= v_cap THEN
    RETURN jsonb_build_object(
      'error',       'AD_CAP_REACHED',
      'views_today', v_count,
      'cap',         v_cap
    );
  END IF;

  -- Lazy energy refill (hours elapsed since last_refill_at)
  v_hours    := FLOOR(EXTRACT(EPOCH FROM (NOW() - v_profile.last_refill_at)) / 3600)::INT;
  v_refilled := LEAST(20, v_profile.current_energy + v_hours);

  -- Record the ad view
  INSERT INTO public.ad_views (user_id, reward_type, reward_amount)
  VALUES (p_user_id, p_reward_type, v_reward_amount);

  IF p_reward_type = 'energy' THEN
    v_new_energy      := LEAST(20, v_refilled + v_reward_amount);
    v_new_last_refill := CASE
      WHEN v_new_energy = 20 THEN NOW()
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
    v_new_coins := v_profile.coins + v_reward_amount;
    v_idem_key  := 'ad_reward_' || p_user_id
                   || '_' || CURRENT_DATE
                   || '_coins_' || (v_count + 1);

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
