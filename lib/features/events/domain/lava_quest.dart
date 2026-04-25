class LavaQuest {
  final String id;
  final String seriesId;
  final String title;
  final String? description;
  final String goalType;
  final int goalValue;
  final int rewardGems;
  final int rewardCoins;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final int progress;
  final DateTime? completedAt;
  final DateTime? rewardClaimedAt;

  const LavaQuest({
    required this.id,
    required this.seriesId,
    required this.title,
    this.description,
    required this.goalType,
    required this.goalValue,
    required this.rewardGems,
    required this.rewardCoins,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.progress,
    this.completedAt,
    this.rewardClaimedAt,
  });

  bool get isCompleted => completedAt != null;
  bool get isRewardClaimed => rewardClaimedAt != null;

  bool get isLive {
    final now = DateTime.now().toUtc();
    return isActive && startsAt.isBefore(now) && endsAt.isAfter(now);
  }

  Duration get timeRemaining {
    final diff = endsAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progressFraction =>
      goalValue > 0 ? (progress / goalValue).clamp(0.0, 1.0) : 0.0;

  factory LavaQuest.fromJson(Map<String, dynamic> json) => LavaQuest(
        id: json['id'] as String,
        seriesId: json['series_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        goalType: json['goal_type'] as String? ?? 'episodes_watched',
        goalValue: (json['goal_value'] as num).toInt(),
        rewardGems: (json['reward_gems'] as num).toInt(),
        rewardCoins: (json['reward_coins'] as num).toInt(),
        startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
        endsAt: DateTime.parse(json['ends_at'] as String).toUtc(),
        isActive: json['is_active'] as bool? ?? true,
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String).toUtc()
            : null,
        rewardClaimedAt: json['reward_claimed_at'] != null
            ? DateTime.parse(json['reward_claimed_at'] as String).toUtc()
            : null,
      );
}
