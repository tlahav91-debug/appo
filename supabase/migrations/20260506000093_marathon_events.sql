-- Marathon events: time-limited series completion challenges
CREATE TABLE IF NOT EXISTS public.marathon_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id uuid NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  title text NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  reward_coins int NOT NULL DEFAULT 200,
  reward_collectible_id uuid REFERENCES public.collectibles(id),
  is_active bool NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.marathon_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "marathon_events_select_public"
  ON public.marathon_events FOR SELECT TO authenticated USING (true);

-- One completion record per user per marathon
CREATE TABLE IF NOT EXISTS public.marathon_completions (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  marathon_id uuid NOT NULL REFERENCES public.marathon_events(id) ON DELETE CASCADE,
  completed_at timestamptz NOT NULL DEFAULT now(),
  reward_claimed_at timestamptz,
  PRIMARY KEY (user_id, marathon_id)
);

ALTER TABLE public.marathon_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "marathon_completions_own"
  ON public.marathon_completions FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
