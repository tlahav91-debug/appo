class SavedDrama {
  final String id;
  final String seriesId;
  final DateTime savedAt;
  // Enriched from join
  final String? title;
  final String? coverUrl;
  final int? totalEpisodes;
  final bool isVip;

  const SavedDrama({
    required this.id,
    required this.seriesId,
    required this.savedAt,
    this.title,
    this.coverUrl,
    this.totalEpisodes,
    this.isVip = false,
  });

  factory SavedDrama.fromJson(Map<String, dynamic> j) {
    final series = j['series'] as Map<String, dynamic>?;
    return SavedDrama(
      id: j['id'] as String,
      seriesId: j['series_id'] as String,
      savedAt: DateTime.parse(j['saved_at'] as String),
      title: series?['title'] as String?,
      coverUrl: series?['cover_url'] as String?,
      totalEpisodes: (series?['total_episodes'] as num?)?.toInt(),
      isVip: series?['is_vip'] as bool? ?? false,
    );
  }
}
