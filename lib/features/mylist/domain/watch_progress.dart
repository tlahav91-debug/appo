class WatchProgress {
  final String id;
  final String seriesId;
  final String episodeId;
  final int progressPct;
  final bool completed;
  final DateTime lastWatchedAt;

  const WatchProgress({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.progressPct,
    required this.completed,
    required this.lastWatchedAt,
  });

  factory WatchProgress.fromJson(Map<String, dynamic> j) => WatchProgress(
    id: j['id'] as String,
    seriesId: j['series_id'] as String,
    episodeId: j['episode_id'] as String,
    progressPct: j['progress_pct'] as int,
    completed: j['completed'] as bool,
    lastWatchedAt: DateTime.parse(j['last_watched_at'] as String),
  );
}
