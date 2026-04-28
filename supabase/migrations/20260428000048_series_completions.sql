CREATE TABLE IF NOT EXISTS public.series_completions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  series_id     UUID        NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  coins_granted INT         NOT NULL DEFAULT 100,
  xp_granted    INT         NOT NULL DEFAULT 50,
  claimed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, series_id)
);

ALTER TABLE public.series_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users read own completions"
  ON public.series_completions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "service_role insert completions"
  ON public.series_completions FOR INSERT
  WITH CHECK (auth.role() = 'service_role');
