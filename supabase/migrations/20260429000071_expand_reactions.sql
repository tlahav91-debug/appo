-- PRD-071: Expand episode reactions from 5 to 12 emojis.
-- Drop the inline CHECK constraint by recreating the column default
-- (PostgreSQL requires dropping and re-adding named constraints; since this
-- constraint was created inline without a name, we use ALTER TABLE ... DROP CONSTRAINT
-- using the auto-generated name pattern, or simply add a new named constraint
-- after removing the old one via a column rewrite).

-- Step 1: drop the existing unnamed check constraint by finding its name.
DO $$
DECLARE
  con_name text;
BEGIN
  SELECT conname INTO con_name
  FROM pg_constraint
  WHERE conrelid = 'public.episode_reactions'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%reaction%';

  IF con_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.episode_reactions DROP CONSTRAINT %I', con_name);
  END IF;
END;
$$;

-- Step 2: add expanded constraint with 12 drama-appropriate emojis.
ALTER TABLE public.episode_reactions
  ADD CONSTRAINT episode_reactions_emoji_check
  CHECK (reaction IN (
    '🔥', '❤️', '😱', '😢', '👏',
    '😂', '🤯', '💔', '👀', '😍', '💜', '⚡'
  ));
