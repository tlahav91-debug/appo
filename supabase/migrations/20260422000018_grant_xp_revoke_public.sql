-- BUG-015-C1: grant_xp was callable by any authenticated user.
-- CREATE FUNCTION grants EXECUTE to PUBLIC by default; revoking closes the exploit.
-- Same pattern as migration 000010 (increment_race_score fix).
REVOKE EXECUTE ON FUNCTION public.grant_xp(UUID, INTEGER, TEXT) FROM PUBLIC;
