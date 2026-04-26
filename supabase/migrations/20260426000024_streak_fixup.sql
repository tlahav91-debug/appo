-- Atomic currency increment used by claim-daily-streak Edge Function
CREATE OR REPLACE FUNCTION increment_currency(uid uuid, d_coins int, d_gems int)
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE profiles SET coins = coins + d_coins, gems = gems + d_gems WHERE id = uid;
$$;

REVOKE EXECUTE ON FUNCTION increment_currency(uuid, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_currency(uuid, int, int) TO service_role;

-- Explicit INSERT policy: only service_role (via Edge Function) may insert check-ins
-- RLS is already enabled; service_role bypasses by default, but this documents intent.
-- No client-side INSERT policy is intentional: direct inserts are blocked.
