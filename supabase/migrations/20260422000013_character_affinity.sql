-- episode_choice_characters: which characters gain affinity from each episode choice
CREATE TABLE public.episode_choice_characters (
  choice_id      UUID     NOT NULL REFERENCES public.episode_choices(id) ON DELETE CASCADE,
  character_id   UUID     NOT NULL REFERENCES public.characters(id) ON DELETE CASCADE,
  affinity_delta SMALLINT NOT NULL DEFAULT 5,
  PRIMARY KEY (choice_id, character_id)
);

ALTER TABLE public.episode_choice_characters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Choice characters are publicly readable"
  ON public.episode_choice_characters FOR SELECT USING (TRUE);

-- apply_choice_affinity: upsert affinity for all characters linked to a choice
CREATE OR REPLACE FUNCTION public.apply_choice_affinity(
  p_user_id   UUID,
  p_choice_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.character_affinity (user_id, character_id, affinity_points, updated_at)
  SELECT p_user_id, ecc.character_id, ecc.affinity_delta, NOW()
  FROM public.episode_choice_characters ecc
  WHERE ecc.choice_id = p_choice_id
  ON CONFLICT (user_id, character_id) DO UPDATE
    SET affinity_points = LEAST(
          public.character_affinity.affinity_points + EXCLUDED.affinity_points,
          32767
        ),
        updated_at = NOW();
END;
$$;

-- service_role only — called by record-choice edge function
GRANT EXECUTE ON FUNCTION public.apply_choice_affinity(UUID, UUID) TO service_role;
