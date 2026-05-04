CREATE TABLE IF NOT EXISTS public.user_achievements (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_key text NOT NULL,
  earned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_key)
);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- Public read — achievement badges are profile-public info, no sensitive data
CREATE POLICY "user_achievements_select_public"
  ON public.user_achievements FOR SELECT TO authenticated
  USING (true);
-- No client INSERT/UPDATE/DELETE — service role only
