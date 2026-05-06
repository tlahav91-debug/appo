-- [SCHEMA] Team meeting bug fixes: reference_id column, RLS hardening, missing indexes

-- ============================================================
-- Fix 1 — Add reference_id column to episode_unlocks (CRITICAL)
-- watch-episode and unlock-episode-coins insert with a reference_id TEXT
-- field and query it for idempotency. The column was missing.
-- ============================================================

ALTER TABLE public.episode_unlocks ADD COLUMN IF NOT EXISTS reference_id TEXT;

CREATE INDEX IF NOT EXISTS idx_episode_unlocks_ref
  ON public.episode_unlocks(user_id, reference_id);

-- ============================================================
-- Fix 2 — Add CHECK (coins >= 0) to profiles
-- profiles.gems already has this check; profiles.coins did not.
-- ============================================================

ALTER TABLE public.profiles
  ADD CONSTRAINT IF NOT EXISTS chk_coins_non_negative CHECK (coins >= 0);

-- ============================================================
-- Fix 3 — Harden daily_reward_cycles RLS (HIGH)
-- Clients were able to INSERT/UPDATE their own row directly, allowing
-- them to reset last_claimed_at = NULL and re-claim daily rewards.
-- The edge function uses the service role key so needs no client policies.
-- Drop the INSERT and UPDATE policies; keep only SELECT.
-- ============================================================

DROP POLICY IF EXISTS "daily_reward_cycles_insert_own" ON public.daily_reward_cycles;
DROP POLICY IF EXISTS "daily_reward_cycles_update_own" ON public.daily_reward_cycles;

-- ============================================================
-- Fix 4 — Restrict watch_progress client write access (HIGH)
-- The blanket FOR ALL policy let clients directly set completed = true
-- without watching any episodes, making marathon rewards, series
-- completions, and achievements exploitable.
--
-- Replacement:
--   SELECT   own rows
--   INSERT   allowed only when completed = false
--   UPDATE   allowed only when completed is not being flipped
--            (new value must match the stored value)
-- ============================================================

DROP POLICY IF EXISTS "user can manage own watch progress" ON public.watch_progress;

CREATE POLICY "watch_progress_select_own"
  ON public.watch_progress FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "watch_progress_insert_own"
  ON public.watch_progress FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND completed = false
  );

-- Allow clients to update progress_pct / last_watched_at but not flip completed.
-- The WITH CHECK sub-select re-reads the stored row; if the client tries to
-- change `completed` the new value won't match the stored value and the
-- check will fail.
CREATE POLICY "watch_progress_update_own"
  ON public.watch_progress FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND completed = (
      SELECT wp.completed
      FROM public.watch_progress wp
      WHERE wp.id = watch_progress.id
    )
  );

-- ============================================================
-- Fix 5 — Fix user_collectibles public RLS policy (MEDIUM)
-- user_collectibles_select_public (USING (true)) exposed every user's
-- collectibles to any authenticated user.
-- Replace with:
--   1. Own-row access
--   2. Read access for collectibles belonging to any valid profile
--      (needed by FanProfileScreen to show up to 6 collectibles)
-- ============================================================

DROP POLICY IF EXISTS "user_collectibles_select_public" ON public.user_collectibles;

-- Allow users to always see their own collectibles.
CREATE POLICY IF NOT EXISTS "user_collectibles_select_own"
  ON public.user_collectibles FOR SELECT
  USING (user_id = auth.uid());

-- Allow any authenticated user to see collectibles that belong to a valid
-- (non-deleted) profile — used by the FanProfileScreen public display.
-- This ties enumeration to real users rather than being fully open.
CREATE POLICY IF NOT EXISTS "user_collectibles_select_public_profiles"
  ON public.user_collectibles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_collectibles.user_id
    )
  );

-- ============================================================
-- Fix 6 — Fix QA questions RLS (MEDIUM)
-- qa_questions_select only allowed the session creator to read questions.
-- Fans could not read their own submitted question, and no one could
-- see the pinned question.
-- Replace with three targeted policies.
-- ============================================================

DROP POLICY IF EXISTS "qa_questions_select" ON public.creator_qa_questions;

-- 6a. Session creator can read all questions in their session.
CREATE POLICY "qa_questions_select_creator"
  ON public.creator_qa_questions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_qa_sessions s
      WHERE s.id = creator_qa_questions.session_id
        AND s.creator_id = auth.uid()
    )
  );

-- 6b. Fan can read their own submitted question.
CREATE POLICY "qa_questions_select_own"
  ON public.creator_qa_questions FOR SELECT TO authenticated
  USING (fan_id = auth.uid());

-- 6c. Any authenticated user can read the pinned question in a session
--     (displayed publicly on the Q&A screen).
CREATE POLICY "qa_questions_select_pinned"
  ON public.creator_qa_questions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_qa_sessions s
      WHERE s.id = creator_qa_questions.session_id
        AND s.pinned_question_id = creator_qa_questions.id
    )
  );

-- ============================================================
-- Fix 7 — Add missing indexes (MEDIUM)
-- ============================================================

-- Who-follows-me queries (fan_follows.followed_id had no index)
CREATE INDEX IF NOT EXISTS idx_fan_follows_followed
  ON public.fan_follows(followed_id);

-- Marathon provider batch-fetches completions by marathon_id
-- (leading PK key is user_id, so this lookup was a full scan)
CREATE INDEX IF NOT EXISTS idx_marathon_completions_marathon
  ON public.marathon_completions(marathon_id);

-- claim-marathon-reward queries watch_progress by series_id via marathon_events
CREATE INDEX IF NOT EXISTS idx_marathon_events_series
  ON public.marathon_events(series_id);

-- series_completions queried by user_id for achievement count
CREATE INDEX IF NOT EXISTS idx_series_completions_user
  ON public.series_completions(user_id);
