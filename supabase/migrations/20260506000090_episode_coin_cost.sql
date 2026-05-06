-- Add coin_cost to episodes: alternative unlock path (spend coins instead of waiting for energy)
ALTER TABLE public.episodes ADD COLUMN IF NOT EXISTS coin_cost int NOT NULL DEFAULT 0;
