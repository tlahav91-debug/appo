CREATE TABLE IF NOT EXISTS episode_reactions (
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  episode_id UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  reaction   TEXT NOT NULL CHECK (reaction IN ('🔥', '❤️', '😱', '😢', '👏')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, episode_id)
);

ALTER TABLE episode_reactions ENABLE ROW LEVEL SECURITY;

-- Users can read all reactions (public counts)
CREATE POLICY "reactions are publicly readable"
  ON episode_reactions FOR SELECT USING (true);

-- Users can upsert their own reaction
CREATE POLICY "users can upsert own reaction"
  ON episode_reactions FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "users can update own reaction"
  ON episode_reactions FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "users can delete own reaction"
  ON episode_reactions FOR DELETE USING (user_id = auth.uid());
