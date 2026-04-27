-- Add is_creator flag to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_creator BOOLEAN NOT NULL DEFAULT false;

-- creator_profiles table
CREATE TABLE IF NOT EXISTS public.creator_profiles (
  id               UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  status           TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  display_name     TEXT NOT NULL,
  bio              TEXT NOT NULL CHECK (char_length(bio) <= 300),
  why_create       TEXT NOT NULL,
  rejection_reason TEXT,
  payout_email     TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.creator_profiles ENABLE ROW LEVEL SECURITY;

-- Creator can read their own row
CREATE POLICY "creator_profiles_select_own" ON public.creator_profiles
  FOR SELECT USING (auth.uid() = id);

-- No direct client writes — Edge Functions use service role
