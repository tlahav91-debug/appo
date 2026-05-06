-- PRD-100: choice_vote_counts — tracks how many users chose each option

CREATE TABLE IF NOT EXISTS public.choice_vote_counts (
  choice_id  UUID PRIMARY KEY REFERENCES public.episode_choices(id) ON DELETE CASCADE,
  vote_count BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.choice_vote_counts ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read vote counts (public stats)
CREATE POLICY "vote_counts_select_authenticated"
  ON public.choice_vote_counts FOR SELECT
  TO authenticated USING (true);

-- Atomic upsert-increment — called by record-choice edge function (service role)
CREATE OR REPLACE FUNCTION public.increment_choice_vote(p_choice_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.choice_vote_counts (choice_id, vote_count)
  VALUES (p_choice_id, 1)
  ON CONFLICT (choice_id) DO UPDATE
  SET vote_count = choice_vote_counts.vote_count + 1,
      updated_at = NOW();
END;
$$;
