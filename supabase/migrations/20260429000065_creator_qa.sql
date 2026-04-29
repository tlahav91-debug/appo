-- creator_qa_sessions
CREATE TABLE public.creator_qa_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  scheduled_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','live','ended')),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.creator_qa_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qa_sessions_select" ON public.creator_qa_sessions FOR SELECT TO authenticated USING (true);
CREATE POLICY "qa_sessions_insert" ON public.creator_qa_sessions FOR INSERT TO authenticated WITH CHECK (creator_id = auth.uid());
CREATE POLICY "qa_sessions_update" ON public.creator_qa_sessions FOR UPDATE TO authenticated USING (creator_id = auth.uid());
CREATE POLICY "qa_sessions_delete" ON public.creator_qa_sessions FOR DELETE TO authenticated USING (creator_id = auth.uid());

-- creator_qa_messages
CREATE TABLE public.creator_qa_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.creator_qa_sessions(id) ON DELETE CASCADE,
  body text NOT NULL,
  delay_seconds int NOT NULL DEFAULT 0,
  position int NOT NULL
);
ALTER TABLE public.creator_qa_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qa_messages_select" ON public.creator_qa_messages FOR SELECT TO authenticated USING (true);
CREATE POLICY "qa_messages_insert" ON public.creator_qa_messages FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.creator_qa_sessions WHERE id = session_id AND creator_id = auth.uid()));
CREATE POLICY "qa_messages_update" ON public.creator_qa_messages FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.creator_qa_sessions WHERE id = session_id AND creator_id = auth.uid()));
CREATE POLICY "qa_messages_delete" ON public.creator_qa_messages FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.creator_qa_sessions WHERE id = session_id AND creator_id = auth.uid()));

CREATE INDEX idx_qa_sessions_creator ON public.creator_qa_sessions(creator_id);
CREATE INDEX idx_qa_sessions_status_scheduled ON public.creator_qa_sessions(status, scheduled_at);
CREATE INDEX idx_qa_messages_session ON public.creator_qa_messages(session_id, position);
