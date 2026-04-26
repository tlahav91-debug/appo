-- BUG-014-C1 / BUG-014-H2: Remove open INSERT RLS policies from both club tables.
-- All inserts must go through SECURITY DEFINER RPCs (create_club / join_club)
-- which enforce one-club-per-user and max-20 checks. Direct client inserts
-- previously bypassed all guards.
DROP POLICY IF EXISTS "Users can create watch clubs" ON public.watch_clubs;
DROP POLICY IF EXISTS "Users can join clubs"          ON public.watch_club_members;

-- BUG-014-H1: Rewrite leave_club with FOR UPDATE lock on watch_clubs row.
-- Without the lock, two concurrent leaves both read v_count = 2, both skip the
-- "delete club if empty" branch, both decrement, leaving count = 0 with no
-- members (zombie club). The FOR UPDATE serialises concurrent leaves.
CREATE OR REPLACE FUNCTION public.leave_club(p_club_id UUID) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_owner_id  UUID;
  v_new_owner UUID;
  v_count     SMALLINT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.watch_club_members
    WHERE club_id = p_club_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'not_a_member';
  END IF;

  -- Lock the club row so concurrent leaves serialise here
  SELECT owner_id, member_count INTO v_owner_id, v_count
  FROM public.watch_clubs WHERE id = p_club_id FOR UPDATE;

  DELETE FROM public.watch_club_members
  WHERE club_id = p_club_id AND user_id = v_user_id;

  IF v_count <= 1 THEN
    DELETE FROM public.watch_clubs WHERE id = p_club_id;
    RETURN;
  END IF;

  UPDATE public.watch_clubs
  SET member_count = member_count - 1
  WHERE id = p_club_id;

  IF v_owner_id = v_user_id THEN
    SELECT user_id INTO v_new_owner
    FROM public.watch_club_members
    WHERE club_id = p_club_id
    ORDER BY joined_at
    LIMIT 1;
    UPDATE public.watch_clubs SET owner_id = v_new_owner WHERE id = p_club_id;
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.leave_club(UUID) TO authenticated;
