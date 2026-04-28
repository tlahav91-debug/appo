-- creator_follows: viewer follows a creator
CREATE TABLE IF NOT EXISTS public.creator_follows (
  follower_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  creator_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  followed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, creator_id)
);
ALTER TABLE public.creator_follows ENABLE ROW LEVEL SECURITY;

-- Users can see who they follow
CREATE POLICY "follows_select_own" ON public.creator_follows
  FOR SELECT USING (auth.uid() = follower_id);

-- Users can follow creators
CREATE POLICY "follows_insert_own" ON public.creator_follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow
CREATE POLICY "follows_delete_own" ON public.creator_follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Public creator profile view — only approved creators, no sensitive fields
CREATE OR REPLACE VIEW public.public_creator_profiles AS
SELECT
  cp.id,
  cp.display_name,
  cp.bio,
  p.avatar_url,
  COUNT(DISTINCT cf.follower_id)::INT AS follower_count
FROM public.creator_profiles cp
JOIN public.profiles p ON p.id = cp.id
LEFT JOIN public.creator_follows cf ON cf.creator_id = cp.id
WHERE cp.status = 'approved'
GROUP BY cp.id, cp.display_name, cp.bio, p.avatar_url;

-- Add a public SELECT policy on creator_profiles for approved rows
-- (only safe columns are exposed via the view; raw table still restricted)
CREATE POLICY "creator_profiles_select_approved" ON public.creator_profiles
  FOR SELECT USING (status = 'approved');
