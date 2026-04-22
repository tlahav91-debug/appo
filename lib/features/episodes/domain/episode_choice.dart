class EpisodeChoice {
  final String id;
  final String episodeId;
  final String label;
  final int rewardCoins;
  final String? collectibleId;
  final String? collectibleName;
  final String? collectibleRarity;

  const EpisodeChoice({
    required this.id,
    required this.episodeId,
    required this.label,
    required this.rewardCoins,
    this.collectibleId,
    this.collectibleName,
    this.collectibleRarity,
  });

  factory EpisodeChoice.fromJson(Map<String, dynamic> j) {
    final coll = j['collectibles'] as Map<String, dynamic>?;
    return EpisodeChoice(
      id: j['id'] as String,
      episodeId: j['episode_id'] as String,
      label: j['label'] as String,
      rewardCoins: (j['reward_coins'] as num?)?.toInt() ?? 10,
      collectibleId: j['collectible_id'] as String?,
      collectibleName: coll?['name'] as String?,
      collectibleRarity: coll?['rarity'] as String?,
    );
  }
}
