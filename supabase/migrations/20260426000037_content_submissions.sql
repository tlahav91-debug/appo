CREATE TABLE IF NOT EXISTS public.content_submissions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  series_id        UUID REFERENCES public.series(id) ON DELETE SET NULL,
  title            TEXT NOT NULL,
  description      TEXT,
  genre            TEXT,
  episode_number   INT NOT NULL DEFAULT 1,
  cf_stream_id     TEXT,
  thumbnail_url    TEXT,
  status           TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','approved','rejected')),
  rejection_reason TEXT,
  submitted_at     TIMESTAMPTZ,
  reviewed_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.content_submissions ENABLE ROW LEVEL SECURITY;

-- Creator can read/update their own draft submissions
CREATE POLICY "submissions_select_own" ON public.content_submissions
  FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "submissions_update_own_draft" ON public.content_submissions
  FOR UPDATE USING (auth.uid() = creator_id AND status = 'draft')
  WITH CHECK (auth.uid() = creator_id AND status = 'draft');

-- No direct INSERT — use Edge Function
CREATE INDEX IF NOT EXISTS content_submissions_creator_idx ON public.content_submissions(creator_id);
CREATE INDEX IF NOT EXISTS content_submissions_status_idx ON public.content_submissions(status);
