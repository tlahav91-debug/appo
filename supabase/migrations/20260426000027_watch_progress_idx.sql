CREATE INDEX IF NOT EXISTS watch_progress_user_series_idx
  ON watch_progress (user_id, series_id);
