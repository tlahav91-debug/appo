-- PRD-015: Fan Level + XP

-- AC-6: profiles.xp must be INTEGER — SMALLINT caps at 32,767 < Level 10 threshold (35,000)
ALTER TABLE public.profiles ALTER COLUMN xp TYPE INTEGER;

-- Static threshold table; seeded once, never mutated by players
CREATE TABLE public.fan_level_thresholds (
  level       SMALLINT PRIMARY KEY CHECK (level BETWEEN 1 AND 10),
  xp_required INTEGER  NOT NULL CHECK (xp_required >= 0),
  label       TEXT     NOT NULL
);

ALTER TABLE public.fan_level_thresholds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Fan level thresholds are publicly readable"
  ON public.fan_level_thresholds FOR SELECT USING (TRUE);

INSERT INTO public.fan_level_thresholds (level, xp_required, label) VALUES
  ( 1,     0, 'New Fan'),
  ( 2,   150, 'Fan'),
  ( 3,   400, 'Devoted Fan'),
  ( 4,   800, 'Super Fan'),
  ( 5,  1500, 'Obsessed'),
  ( 6,  3000, 'Stan'),
  ( 7,  6000, 'Ultra Stan'),
  ( 8, 12000, 'Legend'),
  ( 9, 20000, 'Drama Royalty'),
  (10, 35000, 'Icon');

-- grant_xp: atomically increments xp and recalculates fan_level from thresholds.
-- AC-3: GRANT to service_role only — authenticated must never call this directly.
CREATE OR REPLACE FUNCTION public.grant_xp(
  p_user_id UUID,
  p_amount  INTEGER,
  p_source  TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_xp    INTEGER;
  v_old_level SMALLINT;
  v_new_level SMALLINT;
BEGIN
  UPDATE public.profiles
  SET xp = xp + p_amount
  WHERE id = p_user_id
  RETURNING xp, fan_level INTO v_new_xp, v_old_level;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Profile not found');
  END IF;

  -- Highest level whose entry threshold is <= new total XP
  SELECT COALESCE(MAX(level), 1) INTO v_new_level
  FROM public.fan_level_thresholds
  WHERE xp_required <= v_new_xp;

  IF v_new_level != v_old_level THEN
    UPDATE public.profiles SET fan_level = v_new_level WHERE id = p_user_id;
  END IF;

  RETURN jsonb_build_object(
    'new_xp',        v_new_xp,
    'new_fan_level', v_new_level,
    'leveled_up',    v_new_level > v_old_level
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.grant_xp(UUID, INTEGER, TEXT) TO service_role;
