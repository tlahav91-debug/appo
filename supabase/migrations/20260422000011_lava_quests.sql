-- ============================================================
-- LAVA QUESTS
-- ============================================================

CREATE TABLE public.lava_quests (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id    UUID        NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  title        TEXT        NOT NULL,
  description  TEXT,
  goal_type    TEXT        NOT NULL DEFAULT 'episodes_watched',
  goal_value   SMALLINT    NOT NULL,
  reward_gems  SMALLINT    NOT NULL DEFAULT 10,
  reward_coins SMALLINT    NOT NULL DEFAULT 100,
  starts_at    TIMESTAMPTZ NOT NULL,
  ends_at      TIMESTAMPTZ NOT NULL,
  is_active    BOOLEAN     NOT NULL DEFAULT TRUE
);

ALTER TABLE public.lava_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lava quests are publicly readable"
  ON public.lava_quests FOR SELECT USING (TRUE);

CREATE INDEX idx_lava_quests_active ON public.lava_quests(is_active, ends_at);

-- ============================================================
-- USER QUEST PROGRESS
-- ============================================================

CREATE TABLE public.user_quest_progress (
  user_id           UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id          UUID        NOT NULL REFERENCES public.lava_quests(id) ON DELETE CASCADE,
  progress          SMALLINT    NOT NULL DEFAULT 0,
  completed_at      TIMESTAMPTZ,
  reward_claimed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, quest_id)
);

ALTER TABLE public.user_quest_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own quest progress"
  ON public.user_quest_progress FOR SELECT USING (auth.uid() = user_id);
-- All writes go through SECURITY DEFINER RPCs / service-role edge functions

-- ============================================================
-- increment_quest_progress RPC
-- ============================================================

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
-- No GRANT to authenticated — service role only via edge functions
