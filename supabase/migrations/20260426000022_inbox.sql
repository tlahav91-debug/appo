CREATE TABLE IF NOT EXISTS inbox_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type           TEXT NOT NULL DEFAULT 'reward' CHECK (type IN ('reward', 'announcement', 'event')),
  title          TEXT NOT NULL,
  body           TEXT,
  reward_coins   INT NOT NULL DEFAULT 0,
  reward_gems    INT NOT NULL DEFAULT 0,
  claimed        BOOLEAN NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS inbox_items_user_unclaimed
  ON inbox_items (user_id, claimed, created_at DESC);

ALTER TABLE inbox_items ENABLE ROW LEVEL SECURITY;

-- Users can read own inbox
CREATE POLICY "user can read own inbox"
  ON inbox_items FOR SELECT USING (user_id = auth.uid());

-- Users can update own inbox (for claiming — but actual claim goes through Edge Function)
-- No direct UPDATE policy — claim only via Edge Function using service_role

-- service_role has full access implicitly

-- Seed welcome items for all existing users
INSERT INTO inbox_items (user_id, type, title, body, reward_coins, reward_gems)
SELECT
  id,
  'reward',
  '🎉 Welcome Bonus',
  'Thanks for joining! Here are some coins and gems to get you started.',
  100,
  5
FROM auth.users
ON CONFLICT DO NOTHING;

INSERT INTO inbox_items (user_id, type, title, body, reward_coins, reward_gems)
SELECT
  id,
  'announcement',
  '📺 First Episode Free',
  'Your first episode in any series is always free — no energy needed. Start watching now!',
  0,
  0
FROM auth.users
ON CONFLICT DO NOTHING;
