-- View: 7-day unique-watcher count per series
CREATE OR REPLACE VIEW public.series_trending AS
SELECT
  s.id,
  s.title,
  s.cover_url,
  s.is_vip,
  s.total_episodes,
  s.description,
  s.genre,
  s.created_at,
  COUNT(DISTINCT wp.user_id) AS view_count_7d
FROM public.series s
LEFT JOIN public.watch_progress wp
  ON wp.series_id = s.id
  AND wp.updated_at >= NOW() - INTERVAL '7 days'
GROUP BY s.id
ORDER BY view_count_7d DESC, s.created_at DESC;

GRANT SELECT ON public.series_trending TO authenticated;
