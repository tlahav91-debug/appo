class Episode {
  final String id;
  final String seriesId;
  final String title;
  final int episodeNumber;
  final bool isFree;
  final int energyCost;
  final int coinCost;
  final String? thumbnailUrl;
  final String? synopsis;

  const Episode({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.episodeNumber,
    required this.isFree,
    required this.energyCost,
    this.coinCost = 0,
    this.thumbnailUrl,
    this.synopsis,
  });

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        id: j['id'] as String,
        seriesId: j['series_id'] as String,
        title: j['title'] as String,
        episodeNumber: (j['episode_number'] as num).toInt(),
        isFree: j['is_free'] as bool? ?? false,
        energyCost: (j['energy_cost'] as num?)?.toInt() ?? 5,
        coinCost: (j['coin_cost'] as num?)?.toInt() ?? 0,
        thumbnailUrl: j['thumbnail_url'] as String?,
        synopsis: j['synopsis'] as String?,
      );
}
