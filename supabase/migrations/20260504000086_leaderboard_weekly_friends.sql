-- Weekly XP snapshots
CREATE TABLE IF NOT EXISTS public.weekly_xp_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  week_start date NOT NULL,
  xp_at_start int4 NOT NULL DEFAULT 0,
  CONSTRAINT weekly_xp_snapshots_user_week_key UNIQUE (user_id, week_start)
);
ALTER TABLE public.weekly_xp_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "weekly_xp_snapshots_select_own"
  ON public.weekly_xp_snapshots FOR SELECT
  USING (user_id = auth.uid());

-- Fan follows (minimal schema — follow/unfollow UI ships in PRD-082)
CREATE TABLE IF NOT EXISTS public.fan_follows (
  follower_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  followed_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followed_id)
);
ALTER TABLE public.fan_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fan_follows_select_own"
  ON public.fan_follows FOR SELECT
  USING (follower_id = auth.uid());
CREATE POLICY "fan_follows_insert_own"
  ON public.fan_follows FOR INSERT
  WITH CHECK (follower_id = auth.uid());
CREATE POLICY "fan_follows_delete_own"
  ON public.fan_follows FOR DELETE
  USING (follower_id = auth.uid());

-- Weekly leaderboard RPC: top 100 by XP earned this calendar week
CREATE OR REPLACE FUNCTION public.get_weekly_leaderboard()
RETURNS TABLE(user_id uuid, username text, avatar_url text, fan_level int, weekly_xp int)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.fan_level,
    (p.xp - COALESCE(s.xp_at_start, 0))::int AS weekly_xp
  FROM public.public_fan_profiles p
  LEFT JOIN public.weekly_xp_snapshots s
    ON s.user_id = p.id
    AND s.week_start = date_trunc('week', now())::date
  ORDER BY weekly_xp DESC
  LIMIT 100;
$$;

-- Friends leaderboard RPC: followed fans ranked by all-time XP (caller identity enforced via auth.uid())
CREATE OR REPLACE FUNCTION public.get_friends_leaderboard()
RETURNS TABLE(user_id uuid, username text, avatar_url text, fan_level int, xp int)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.fan_level,
    p.xp
  FROM public.public_fan_profiles p
  INNER JOIN public.fan_follows f
    ON f.followed_id = p.id AND f.follower_id = auth.uid()
  ORDER BY p.xp DESC
  LIMIT 100;
$$;
