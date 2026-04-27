CREATE TABLE IF NOT EXISTS public.pass_watch_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  episode_id  UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  creator_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  watched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, episode_id)
);
ALTER TABLE public.pass_watch_events ENABLE ROW LEVEL SECURITY;
-- No SELECT policy for clients; service-role only writes
