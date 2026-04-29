-- BUG-068-H2: Add UNIQUE constraint on (submission_id, period) so that
-- tally-creator-earnings upsert ON CONFLICT clause works correctly.
-- Drop the plain index first to avoid redundancy.
DROP INDEX IF EXISTS idx_creator_earnings_submission;

ALTER TABLE public.creator_earnings
  ADD CONSTRAINT uq_creator_earnings_submission_period
  UNIQUE (submission_id, period);
