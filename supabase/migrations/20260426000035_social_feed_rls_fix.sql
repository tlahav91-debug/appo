-- Fix PRD-041: scope activity_events SELECT to own events + followed users only
DROP POLICY IF EXISTS "activity_events_select" ON public.activity_events;

CREATE POLICY "activity_events_select_followers" ON public.activity_events
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.user_follows
      WHERE follower_id = auth.uid()
        AND following_id = activity_events.user_id
    )
  );

-- Prevent direct client-side INSERT (only service role via Edge Function should write)
CREATE POLICY "activity_events_no_direct_insert" ON public.activity_events
  FOR INSERT WITH CHECK (false);

-- Add missing indexes for JOIN performance
CREATE INDEX IF NOT EXISTS activity_likes_event_idx ON public.activity_likes(event_id);
CREATE INDEX IF NOT EXISTS activity_comments_event_idx ON public.activity_comments(event_id);
