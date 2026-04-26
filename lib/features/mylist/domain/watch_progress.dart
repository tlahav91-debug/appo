class WatchProgress {
  final String id;
  final String seriesId;
  final String episodeId;
  final int progressPct;
  final bool completed;
  final DateTime lastWatchedAt;
  // Enriched from join
  final String? seriesTitle;
  final String? episodeTitle;
  final int? episodeNumber;
  final String? coverUrl;

  const WatchProgress({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.progressPct,
    required this.completed,
    required this.lastWatchedAt,
    this.seriesTitle,
    this.episodeTitle,
    this.episodeNumber,
    this.coverUrl,
  });

  factory WatchProgress.fromJson(Map<String, dynamic> j) {
    final episode = j['episodes'] as Map<String, dynamic>?;
    final series = episode?['series'] as Map<String, dynamic>?;
    return WatchProgress(
      id: j['id'] as String,
      seriesId: j['series_id'] as String,
      episodeId: j['episode_id'] as String,
      progressPct: j['progress_pct'] as int,
      completed: j['completed'] as bool,
      lastWatchedAt: DateTime.parse(j['last_watched_at'] as String),
      episodeTitle: episode?['title'] as String?,
      episodeNumber: (episode?['episode_number'] as num?)?.toInt(),
      seriesTitle: series?['title'] as String?,
      coverUrl: series?['cover_url'] as String?,
    );
  }
}
