-- PRD-017: Push Notification token storage
CREATE TABLE public.push_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

-- Users can read and delete their own tokens; upsert goes through Edge Function
CREATE POLICY "users_select_own_tokens" ON public.push_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_delete_own_tokens" ON public.push_tokens
  FOR DELETE USING (auth.uid() = user_id);

GRANT SELECT, DELETE ON public.push_tokens TO authenticated;
GRANT ALL ON public.push_tokens TO service_role;
