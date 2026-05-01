-- PRD-077: Fan Public Profile Page
-- Allow authenticated users to read public profile fields of any user

CREATE POLICY "profiles_select_public" ON public.profiles
  FOR SELECT TO authenticated
  USING (true);

-- Allow authenticated users to read any user's collectibles (public profile display)
CREATE POLICY "user_collectibles_select_public" ON public.user_collectibles
  FOR SELECT TO authenticated
  USING (true);
