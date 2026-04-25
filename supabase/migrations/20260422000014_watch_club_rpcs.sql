-- club_weekly_leaderboard: members ranked by episodes watched this ISO week
CREATE OR REPLACE FUNCTION public.club_weekly_leaderboard(p_club_id UUID)
RETURNS TABLE(
  user_id            UUID,
  username           TEXT,
  avatar_url         TEXT,
  episodes_this_week BIGINT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    wcm.user_id,
    p.username,
    p.avatar_url,
    COUNT(uec.id) AS episodes_this_week
  FROM public.watch_club_members wcm
  JOIN public.profiles p ON p.id = wcm.user_id
  LEFT JOIN public.user_episode_choices uec
    ON uec.user_id = wcm.user_id
   AND uec.created_at >= date_trunc('week', NOW() AT TIME ZONE 'UTC')
  WHERE wcm.club_id = p_club_id
  GROUP BY wcm.user_id, p.username, p.avatar_url
  ORDER BY episodes_this_week DESC;
$$;
GRANT EXECUTE ON FUNCTION public.club_weekly_leaderboard(UUID) TO authenticated;

-- create_club: atomic create + auto-join owner; enforces one-club-per-user
CREATE OR REPLACE FUNCTION public.create_club(
  p_name        TEXT,
  p_description TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_club_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM public.watch_club_members WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'already_in_club';
  END IF;

  INSERT INTO public.watch_clubs (name, description, owner_id, member_count)
  VALUES (p_name, p_description, v_user_id, 1)
  RETURNING id INTO v_club_id;

  INSERT INTO public.watch_club_members (club_id, user_id)
  VALUES (v_club_id, v_user_id);

  RETURN v_club_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_club(TEXT, TEXT) TO authenticated;

-- join_club: enforces one-club-per-user and max 20 members
CREATE OR REPLACE FUNCTION public.join_club(p_club_id UUID) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count   SMALLINT;
BEGIN
  IF EXISTS (SELECT 1 FROM public.watch_club_members WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'already_in_club';
  END IF;

  SELECT member_count INTO v_count FROM public.watch_clubs WHERE id = p_club_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'club_not_found';
  END IF;
  IF v_count >= 20 THEN
    RAISE EXCEPTION 'club_full';
  END IF;

  INSERT INTO public.watch_club_members (club_id, user_id) VALUES (p_club_id, v_user_id);
  UPDATE public.watch_clubs SET member_count = member_count + 1 WHERE id = p_club_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.join_club(UUID) TO authenticated;

-- leave_club: removes member, updates count, transfers ownership or deletes if empty
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

  SELECT owner_id, member_count INTO v_owner_id, v_count
  FROM public.watch_clubs WHERE id = p_club_id;

  DELETE FROM public.watch_club_members WHERE club_id = p_club_id AND user_id = v_user_id;

  IF v_count <= 1 THEN
    DELETE FROM public.watch_clubs WHERE id = p_club_id;
    RETURN;
  END IF;

  UPDATE public.watch_clubs SET member_count = member_count - 1 WHERE id = p_club_id;

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
