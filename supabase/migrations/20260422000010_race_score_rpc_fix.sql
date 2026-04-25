-- C-1 fix: remove public grant — increment_race_score must only be called by service role
REVOKE EXECUTE ON FUNCTION public.increment_race_score(UUID, UUID) FROM authenticated;
