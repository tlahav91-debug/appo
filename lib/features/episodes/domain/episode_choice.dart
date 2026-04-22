class EpisodeChoice {
  final String id;
  final String episodeId;
  final String label;
  final int rewardCoins;

  const EpisodeChoice({
    required this.id,
    required this.episodeId,
    required this.label,
    required this.rewardCoins,
  });

  factory EpisodeChoice.fromJson(Map<String, dynamic> j) => EpisodeChoice(
        id: j['id'] as String,
        episodeId: j['episode_id'] as String,
        label: j['label'] as String,
        rewardCoins: (j['reward_coins'] as num?)?.toInt() ?? 10,
      );
}
