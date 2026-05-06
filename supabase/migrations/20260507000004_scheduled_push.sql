-- PRD-099: scheduled push notifications table
-- notification_prefs.energy_reminder key lives inside the existing JSONB column on profiles
-- (no schema change needed — absent key is treated as true by schedule-energy-reminder)

CREATE TABLE IF NOT EXISTS public.scheduled_push_notifications (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type           TEXT NOT NULL,
  scheduled_for  TIMESTAMPTZ NOT NULL,
  payload        JSONB NOT NULL DEFAULT '{}',
  sent_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_scheduled_push_user_type UNIQUE (user_id, type)
);

ALTER TABLE public.scheduled_push_notifications ENABLE ROW LEVEL SECURITY;
-- Service-role only — no client reads/writes
