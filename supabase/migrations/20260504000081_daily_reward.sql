CREATE TABLE IF NOT EXISTS public.daily_reward_cycles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cycle_day smallint NOT NULL DEFAULT 1 CHECK (cycle_day BETWEEN 1 AND 7),
  last_claimed_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT daily_reward_cycles_user_id_key UNIQUE (user_id)
);

ALTER TABLE public.daily_reward_cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_reward_cycles_select_own"
  ON public.daily_reward_cycles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "daily_reward_cycles_insert_own"
  ON public.daily_reward_cycles FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "daily_reward_cycles_update_own"
  ON public.daily_reward_cycles FOR UPDATE
  USING (user_id = auth.uid());
