-- [SCHEMA] Integrity fixes: BUG-001, BUG-002, BUG-003

-- ============================================================
-- BUG-003 (High): Prevent episode choice without prior unlock
-- A user must have an episode_unlocks row (or the episode must
-- be free) before a choice can be recorded.
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_episode_unlocked()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  ep_is_free BOOLEAN;
BEGIN
  SELECT is_free INTO ep_is_free
  FROM public.episodes
  WHERE id = NEW.episode_id;

  -- Free episodes don't require an unlock row
  IF ep_is_free THEN
    RETURN NEW;
  END IF;

  -- Paid episodes must have a matching unlock row
  IF NOT EXISTS (
    SELECT 1 FROM public.episode_unlocks
    WHERE user_id = NEW.user_id AND episode_id = NEW.episode_id
  ) THEN
    RAISE EXCEPTION 'Episode not unlocked: user % has not unlocked episode %',
      NEW.user_id, NEW.episode_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_episode_unlock_before_choice
  BEFORE INSERT ON public.user_episode_choices
  FOR EACH ROW EXECUTE FUNCTION public.check_episode_unlocked();

-- ============================================================
-- BUG-001 (Medium): Prevent joining inactive or expired races
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_race_active()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  race_ok BOOLEAN;
BEGIN
  SELECT (is_active = TRUE AND ends_at > NOW())
  INTO race_ok
  FROM public.races
  WHERE id = NEW.race_id;

  IF race_ok IS NULL OR NOT race_ok THEN
    RAISE EXCEPTION 'Race % is not currently active', NEW.race_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_active_race_on_join
  BEFORE INSERT ON public.race_participants
  FOR EACH ROW EXECUTE FUNCTION public.check_race_active();

-- ============================================================
-- BUG-002 (Medium): Cap watch club creation at 3 per user
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_watch_club_limit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  club_count INT;
BEGIN
  SELECT COUNT(*) INTO club_count
  FROM public.watch_clubs
  WHERE owner_id = NEW.owner_id;

  IF club_count >= 3 THEN
    RAISE EXCEPTION 'Watch club limit reached: a user may own at most 3 clubs';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_watch_club_limit
  BEFORE INSERT ON public.watch_clubs
  FOR EACH ROW EXECUTE FUNCTION public.check_watch_club_limit();
