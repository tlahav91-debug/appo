-- Add notification_prefs to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS notification_prefs JSONB NOT NULL
    DEFAULT '{"new_episodes":true,"streak_reminder":true,"creator_updates":true,"inbox_rewards":true}';
