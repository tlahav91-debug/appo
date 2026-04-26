CREATE TABLE IF NOT EXISTS meta_unlocks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type    TEXT NOT NULL CHECK (item_type IN ('room', 'outfit', 'mood')),
  item_id      TEXT NOT NULL,
  unlocked_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, item_type, item_id)
);
ALTER TABLE meta_unlocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user can view own unlocks" ON meta_unlocks FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "user can insert own unlocks" ON meta_unlocks FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS user_meta_profile (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  room_id     TEXT NOT NULL DEFAULT 'apartment',
  outfit_id   TEXT NOT NULL DEFAULT 'casual',
  mood_id     TEXT NOT NULL DEFAULT 'chill',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE user_meta_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user can view own meta profile" ON user_meta_profile FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "user can update own meta profile" ON user_meta_profile FOR UPDATE USING (user_id = auth.uid());
