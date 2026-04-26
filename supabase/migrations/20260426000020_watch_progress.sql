-- watch_progress: tracks per-user per-episode watch position
CREATE TABLE IF NOT EXISTS watch_progress (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  series_id      UUID NOT NULL,
  episode_id     UUID NOT NULL,
  progress_pct   SMALLINT NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  completed      BOOLEAN NOT NULL DEFAULT false,
  last_watched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, episode_id)
);

CREATE INDEX IF NOT EXISTS watch_progress_user_recent
  ON watch_progress (user_id, last_watched_at DESC);

ALTER TABLE watch_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user can manage own watch progress"
  ON watch_progress FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- saved_dramas: bookmarked series
CREATE TABLE IF NOT EXISTS saved_dramas (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  series_id  UUID NOT NULL,
  saved_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, series_id)
);

ALTER TABLE saved_dramas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user can manage own saved dramas"
  ON saved_dramas FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
