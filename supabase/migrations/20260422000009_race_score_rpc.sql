-- increment_race_score: atomically bump episodes_watched for the active race in a series
CREATE OR REPLACE FUNCTION public.increment_race_score(
  p_user_id   UUID,
  p_series_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_race_id UUID;
BEGIN
  SELECT id INTO v_race_id
  FROM public.races
  WHERE series_id = p_series_id
    AND is_active = TRUE
    AND ends_at > NOW()
  LIMIT 1;

  IF v_race_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.race_participants
  SET episodes_watched = episodes_watched + 1
  WHERE user_id = p_user_id
    AND race_id = v_race_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_race_score(UUID, UUID) TO authenticated;
