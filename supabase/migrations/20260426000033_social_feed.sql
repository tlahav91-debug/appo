-- user_follows
CREATE TABLE IF NOT EXISTS public.user_follows (
  follower_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_can_see_follows" ON public.user_follows FOR SELECT USING (true);
CREATE POLICY "users_manage_own_follows" ON public.user_follows
  FOR ALL USING (auth.uid() = follower_id) WITH CHECK (auth.uid() = follower_id);

-- activity_events
CREATE TABLE IF NOT EXISTS public.activity_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  episode_id   UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  series_id    UUID REFERENCES public.series(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, episode_id)
);
ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_events_select" ON public.activity_events FOR SELECT USING (true);
CREATE INDEX IF NOT EXISTS activity_events_user_idx ON public.activity_events(user_id);
CREATE INDEX IF NOT EXISTS activity_events_created_idx ON public.activity_events(created_at DESC);

-- activity_likes
CREATE TABLE IF NOT EXISTS public.activity_likes (
  user_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id  UUID NOT NULL REFERENCES public.activity_events(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, event_id)
);
ALTER TABLE public.activity_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "likes_select" ON public.activity_likes FOR SELECT USING (true);
CREATE POLICY "likes_manage_own" ON public.activity_likes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- activity_comments
CREATE TABLE IF NOT EXISTS public.activity_comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id   UUID NOT NULL REFERENCES public.activity_events(id) ON DELETE CASCADE,
  content    TEXT NOT NULL CHECK (char_length(content) <= 280),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.activity_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comments_select" ON public.activity_comments FOR SELECT USING (true);
CREATE POLICY "comments_insert" ON public.activity_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_delete_own" ON public.activity_comments
  FOR DELETE USING (auth.uid() = user_id);
