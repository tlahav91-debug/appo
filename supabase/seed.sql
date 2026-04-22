-- Seed data for AI Drama Game
-- Auth users are created via Supabase Auth — no seed needed for profiles.
-- The on_auth_user_created trigger auto-creates a profiles row on sign-up.

-- Verify trigger exists
SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
