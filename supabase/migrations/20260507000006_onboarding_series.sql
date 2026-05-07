-- PRD-104: mark one series as the onboarding entry point
ALTER TABLE public.series
  ADD COLUMN IF NOT EXISTS is_onboarding_series BOOLEAN NOT NULL DEFAULT false;

-- Set the first non-VIP series as the onboarding series
UPDATE public.series
  SET is_onboarding_series = true
  WHERE id = (
    SELECT id FROM public.series
    WHERE is_vip = false
    ORDER BY created_at ASC
    LIMIT 1
  );
