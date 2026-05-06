class MarathonEvent {
  final String id;
  final String seriesId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int rewardCoins;
  final String? rewardCollectibleId;
  final bool rewardClaimed;

  const MarathonEvent({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.rewardCoins,
    this.rewardCollectibleId,
    this.rewardClaimed = false,
  });

  bool get isLive {
    final now = DateTime.now().toUtc();
    return startsAt.isBefore(now) && endsAt.isAfter(now);
  }

  Duration get timeRemaining {
    final diff = endsAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory MarathonEvent.fromJson(Map<String, dynamic> j,
      {bool rewardClaimed = false}) =>
      MarathonEvent(
        id: j['id'] as String,
        seriesId: j['series_id'] as String,
        title: j['title'] as String,
        startsAt: DateTime.parse(j['starts_at'] as String).toUtc(),
        endsAt: DateTime.parse(j['ends_at'] as String).toUtc(),
        rewardCoins: (j['reward_coins'] as num?)?.toInt() ?? 200,
        rewardCollectibleId: j['reward_collectible_id'] as String?,
        rewardClaimed: rewardClaimed,
      );
}
