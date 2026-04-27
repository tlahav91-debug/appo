CREATE OR REPLACE VIEW public.creator_episode_stats AS
SELECT
  e.id            AS episode_id,
  e.creator_id,
  e.title,
  e.episode_number,
  COUNT(DISTINCT eu.user_id)::INT                                         AS view_count,
  ROUND(COALESCE(AVG(wp.progress_pct), 0)::NUMERIC, 1)                   AS avg_completion_pct,
  COALESCE(SUM(ce.energy_gate_revenue_usd + ce.subscription_share_usd), 0)::NUMERIC(10,4) AS total_earnings_usd
FROM public.episodes e
LEFT JOIN public.episode_unlocks eu ON eu.episode_id = e.id
LEFT JOIN public.watch_progress  wp ON wp.episode_id = e.id
LEFT JOIN public.creator_earnings ce ON ce.episode_id = e.id AND ce.creator_id = e.creator_id
GROUP BY e.id, e.creator_id, e.title, e.episode_number;
