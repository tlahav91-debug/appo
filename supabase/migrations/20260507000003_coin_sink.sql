-- PRD-094: Set non-zero coin_cost on paid episodes; add Premium Choices columns

-- Standard paid episodes (not free, not yet priced): 30 coins
UPDATE episodes
SET coin_cost = 30
WHERE is_free = false
  AND coin_cost = 0;

-- Finale episodes (highest episode_number per series): 50 coins
UPDATE episodes
SET coin_cost = 50
WHERE id IN (
  SELECT DISTINCT ON (series_id) id
  FROM episodes
  WHERE is_free = false
  ORDER BY series_id, episode_number DESC
);

-- VIP series episodes: 0 coins (pass gate is sufficient)
UPDATE episodes
SET coin_cost = 0
WHERE series_id IN (SELECT id FROM series WHERE is_vip = true);

-- Premium Choices: add columns to episode_choices
ALTER TABLE episode_choices
  ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS premium_coin_cost INT NOT NULL DEFAULT 0;
