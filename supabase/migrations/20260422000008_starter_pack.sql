-- [SCHEMA] Starter Pack — tracks one-time purchase on profile

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS starter_pack_purchased_at TIMESTAMPTZ;
