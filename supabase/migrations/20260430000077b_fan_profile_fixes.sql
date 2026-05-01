-- BUG-077-C1: Replace USING (true) policy with a restricted view
-- Drop the overly-permissive policy added in 20260430000077
DROP POLICY IF EXISTS "profiles_select_public" ON public.profiles;

-- Safe public read via view — only non-sensitive columns exposed
CREATE OR REPLACE VIEW public.public_fan_profiles AS
  SELECT id, username, avatar_url, fan_level, xp FROM public.profiles;

GRANT SELECT ON public.public_fan_profiles TO authenticated;
