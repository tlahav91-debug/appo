-- PRD-105: streak shield flag + user timezone on profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS streak_shield_available BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS user_timezone TEXT NOT NULL DEFAULT 'UTC';
