CREATE TABLE public.creator_qa_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.creator_qa_sessions(id) ON DELETE CASCADE,
  fan_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (session_id, fan_id)
);
ALTER TABLE public.creator_qa_questions ENABLE ROW LEVEL SECURITY;

-- Only the session's creator can read questions
CREATE POLICY "qa_questions_select" ON public.creator_qa_questions FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.creator_qa_sessions
    WHERE id = session_id AND creator_id = auth.uid()
  ));

-- Fan can insert their own question only when session is live
CREATE POLICY "qa_questions_insert" ON public.creator_qa_questions FOR INSERT TO authenticated
  WITH CHECK (
    fan_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.creator_qa_sessions
      WHERE id = session_id AND status = 'live'
    )
  );

ALTER TABLE public.creator_qa_sessions
  ADD COLUMN pinned_question_id uuid REFERENCES public.creator_qa_questions(id) ON DELETE SET NULL;

CREATE INDEX idx_qa_questions_session ON public.creator_qa_questions(session_id, created_at);
