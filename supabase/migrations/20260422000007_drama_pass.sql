-- [SCHEMA] Drama Pass — adds last_pass_bonus_at tracking + atomic daily bonus RPC

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_pass_bonus_at TIMESTAMPTZ;

-- Atomic daily +5 energy for Drama Pass holders.
-- Returns NULL rows when bonus was already claimed today or pass is inactive.
CREATE OR REPLACE FUNCTION public.claim_pass_bonus(p_user_id UUID)
RETURNS TABLE(new_energy INTEGER, claimed_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.profiles
  SET
    current_energy    = LEAST(current_energy + 5, 20),
    last_pass_bonus_at = NOW()
  WHERE id = p_user_id
    AND drama_pass_active = TRUE
    AND (last_pass_bonus_at IS NULL OR last_pass_bonus_at::date < CURRENT_DATE)
  RETURNING current_energy, last_pass_bonus_at;
END;
$$;

-- Callable by authenticated users (only their own row is touched via WHERE id = p_user_id)
GRANT EXECUTE ON FUNCTION public.claim_pass_bonus(UUID) TO authenticated;
