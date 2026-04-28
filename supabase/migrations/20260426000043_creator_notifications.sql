CREATE TABLE IF NOT EXISTS public.creator_notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN (
                'content_approved','content_rejected','payout_processed',
                'milestone_100_views','milestone_1k_views','milestone_10k_views',
                'new_episode_from_followed'
              )),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  metadata    JSONB NOT NULL DEFAULT '{}',
  is_read     BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.creator_notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "notifications_select_own" ON public.creator_notifications
  FOR SELECT USING (auth.uid() = user_id);

-- No client INSERT/UPDATE/DELETE — service role only
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.creator_notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.creator_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_unread_idx ON public.creator_notifications(user_id, is_read) WHERE is_read = false;
