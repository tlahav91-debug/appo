CREATE TABLE IF NOT EXISTS series_ratings (
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  series_id  UUID NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, series_id)
);

ALTER TABLE series_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ratings are publicly readable"
  ON series_ratings FOR SELECT USING (true);

CREATE POLICY "users can insert own rating"
  ON series_ratings FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "users can update own rating"
  ON series_ratings FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
