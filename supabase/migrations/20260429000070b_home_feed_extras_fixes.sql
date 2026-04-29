-- BUG-070-H1: Grant SELECT on creator_spotlight view to authenticated users.
GRANT SELECT ON public.creator_spotlight TO authenticated;

-- BUG-070-M1: Revoke EXECUTE from PUBLIC on fn_new_from_following —
-- only authenticated users should call it (returns empty for anon anyway,
-- but unnecessary exposure).
REVOKE EXECUTE ON FUNCTION public.fn_new_from_following() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_new_from_following() TO authenticated;

-- BUG-070-M3: Replace fn_new_from_following with corrected version that
-- returns episodes ordered by submitted_at DESC (most recent first),
-- not by series_id UUID order imposed by DISTINCT ON.
CREATE OR REPLACE FUNCTION public.fn_new_from_following()
RETURNS TABLE (
  submission_id   uuid,
  episode_title   text,
  episode_number  int,
  series_id       uuid,
  series_title    text,
  cover_url       text,
  creator_id      uuid,
  creator_name    text,
  creator_avatar  text,
  submitted_at    timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    sub.submission_id,
    sub.episode_title,
    sub.episode_number,
    sub.series_id,
    sub.series_title,
    sub.cover_url,
    sub.creator_id,
    sub.creator_name,
    sub.creator_avatar,
    sub.submitted_at
  FROM (
    SELECT DISTINCT ON (cs.series_id)
      cs.id            AS submission_id,
      cs.title         AS episode_title,
      cs.episode_number,
      s.id             AS series_id,
      s.title          AS series_title,
      s.cover_url,
      cp.id            AS creator_id,
      cp.display_name  AS creator_name,
      p.avatar_url     AS creator_avatar,
      cs.created_at    AS submitted_at
    FROM creator_follows cf
    JOIN content_submissions cs
      ON cs.creator_id = cf.creator_id AND cs.status = 'approved'
    JOIN series s ON s.id = cs.series_id
    JOIN creator_profiles cp ON cp.id = cf.creator_id
    JOIN profiles p ON p.id = cf.creator_id
    WHERE cf.follower_id = auth.uid()
    ORDER BY cs.series_id, cs.created_at DESC
  ) sub
  ORDER BY sub.submitted_at DESC
  LIMIT 20;
$$;

REVOKE EXECUTE ON FUNCTION public.fn_new_from_following() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_new_from_following() TO authenticated;
