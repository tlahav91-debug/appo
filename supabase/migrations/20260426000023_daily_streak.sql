CREATE TABLE IF NOT EXISTS daily_check_ins (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  streak_day   SMALLINT NOT NULL CHECK (streak_day BETWEEN 1 AND 7),
  reward_coins INT NOT NULL DEFAULT 0,
  reward_gems  INT NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS daily_check_ins_user_day
  ON daily_check_ins (user_id, (checked_in_at::date));

CREATE INDEX IF NOT EXISTS daily_check_ins_user_recent
  ON daily_check_ins (user_id, checked_in_at DESC);

ALTER TABLE daily_check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user can read own check-ins"
  ON daily_check_ins FOR SELECT USING (user_id = auth.uid());
