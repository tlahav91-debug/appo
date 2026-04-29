-- Daily analytics snapshots per episode
CREATE TABLE public.creator_episode_analytics (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  submission_id      uuid NOT NULL REFERENCES public.content_submissions(id) ON DELETE CASCADE,
  date               date NOT NULL,
  view_count         int NOT NULL DEFAULT 0,
  avg_completion_pct numeric(5,2) NOT NULL DEFAULT 0,
  revenue_scrolls    int NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (submission_id, date)
);
ALTER TABLE public.creator_episode_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "episode_analytics_select_own" ON public.creator_episode_analytics
  FOR SELECT TO authenticated USING (creator_id = auth.uid());
CREATE INDEX idx_episode_analytics_submission
  ON public.creator_episode_analytics(submission_id, date DESC);

-- Add avg_completion_pct to creator_earnings monthly rollup
ALTER TABLE public.creator_earnings
  ADD COLUMN IF NOT EXISTS avg_completion_pct numeric(5,2) NOT NULL DEFAULT 0;
