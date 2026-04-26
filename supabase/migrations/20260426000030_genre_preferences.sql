ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS genre_preferences TEXT[] NOT NULL DEFAULT '{}';
