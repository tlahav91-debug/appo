-- Fix PRD-044: drop the correct pre-existing open policies that were missed in migration 032

-- episode_choices: drop the actual open SELECT policy
DROP POLICY IF EXISTS "Episode choices are publicly readable" ON episode_choices;

-- episode_reactions: drop the actual open INSERT policy
DROP POLICY IF EXISTS "users can upsert own reaction" ON episode_reactions;
