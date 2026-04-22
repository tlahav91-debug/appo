class Collectible {
  final String id;
  final String seriesId;
  final String episodeId;
  final String name;
  final String? imageUrl;
  final String rarity;

  const Collectible({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.name,
    this.imageUrl,
    required this.rarity,
  });

  factory Collectible.fromJson(Map<String, dynamic> j) => Collectible(
        id: j['id'] as String,
        seriesId: j['series_id'] as String,
        episodeId: j['episode_id'] as String,
        name: j['name'] as String,
        imageUrl: j['image_url'] as String?,
        rarity: j['rarity'] as String? ?? 'common',
      );
}
