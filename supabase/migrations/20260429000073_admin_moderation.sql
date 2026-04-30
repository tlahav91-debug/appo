-- PRD-073: Admin Content Moderation
-- Adds is_admin flag and admin-scoped RLS policies.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- Admins can SELECT all submissions (existing policy covers own only)
CREATE POLICY "submissions_select_admin" ON public.content_submissions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can SELECT all creator_profiles (for display_name lookup)
CREATE POLICY "creator_profiles_select_admin" ON public.creator_profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );
