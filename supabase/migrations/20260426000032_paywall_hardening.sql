-- Drop the open SELECT policy on episode_choices
DROP POLICY IF EXISTS "episode_choices_select" ON episode_choices;
DROP POLICY IF EXISTS "Public read episode_choices" ON episode_choices;
DROP POLICY IF EXISTS "Anyone can read episode choices" ON episode_choices;

-- Create entitlement-gated SELECT policy
CREATE POLICY "choices_if_unlocked_or_free" ON episode_choices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM episodes e
      WHERE e.id = episode_choices.episode_id
        AND (
          e.is_free = true
          OR EXISTS (
            SELECT 1 FROM episode_unlocks eu
            WHERE eu.episode_id = episode_choices.episode_id
              AND eu.user_id = auth.uid()
          )
        )
    )
  );

-- Tighten episode_reactions INSERT: require unlock or free
DROP POLICY IF EXISTS "Users can insert their reactions" ON episode_reactions;
DROP POLICY IF EXISTS "episode_reactions_insert" ON episode_reactions;

CREATE POLICY "reactions_if_unlocked_or_free" ON episode_reactions
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM episodes e
      WHERE e.id = episode_reactions.episode_id
        AND (
          e.is_free = true
          OR EXISTS (
            SELECT 1 FROM episode_unlocks eu
            WHERE eu.episode_id = episode_reactions.episode_id
              AND eu.user_id = auth.uid()
          )
        )
    )
  );
