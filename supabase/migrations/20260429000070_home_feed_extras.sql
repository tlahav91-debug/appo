-- PRD-070: Fan Discovery & Home Feed Redesign
-- Adds fn_new_from_following() RPC and creator_spotlight view

-- ---------------------------------------------------------------------------
-- RPC: fn_new_from_following
-- Returns the latest approved episode per series from creators the caller follows.
-- ---------------------------------------------------------------------------
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
  JOIN content_submissions cs ON cs.creator_id = cf.creator_id AND cs.status = 'approved'
  JOIN series s ON s.id = cs.series_id
  JOIN creator_profiles cp ON cp.id = cf.creator_id
  JOIN profiles p ON p.id = cf.creator_id
  WHERE cf.follower_id = auth.uid()
  ORDER BY cs.series_id, cs.created_at DESC
  LIMIT 20;
$$;

GRANT EXECUTE ON FUNCTION public.fn_new_from_following() TO authenticated;

-- ---------------------------------------------------------------------------
-- View: creator_spotlight
-- Most-followed creators with recent approved content, for the spotlight card.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.creator_spotlight AS
SELECT
  pcp.id,
  pcp.display_name,
  pcp.bio,
  pcp.avatar_url,
  pcp.follower_count,
  COUNT(DISTINCT s.id) AS series_count
FROM public.public_creator_profiles pcp
LEFT JOIN public.content_submissions cs ON cs.creator_id = pcp.id AND cs.status = 'approved'
LEFT JOIN public.series s ON s.id = cs.series_id
GROUP BY pcp.id, pcp.display_name, pcp.bio, pcp.avatar_url, pcp.follower_count
ORDER BY pcp.follower_count DESC;
