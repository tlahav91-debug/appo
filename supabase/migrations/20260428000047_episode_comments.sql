CREATE TABLE IF NOT EXISTS public.episode_comments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_id  UUID        NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body        TEXT        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 500),
  deleted_at  TIMESTAMPTZ NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.episode_comments ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read: all non-deleted + their own deleted
CREATE POLICY "read episode comments"
  ON public.episode_comments FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL OR user_id = auth.uid());

-- Only service_role may INSERT (Edge Function does this)
CREATE POLICY "service_role insert comments"
  ON public.episode_comments FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Only service_role may UPDATE (soft-delete via Edge Function)
CREATE POLICY "service_role soft-delete comments"
  ON public.episode_comments FOR UPDATE
  USING (auth.role() = 'service_role');

CREATE INDEX idx_episode_comments_episode ON public.episode_comments(episode_id, created_at DESC);
