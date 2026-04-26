class InboxItem {
  final String id;
  final String type; // 'reward' | 'announcement' | 'event'
  final String title;
  final String? body;
  final int rewardCoins;
  final int rewardGems;
  final bool claimed;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const InboxItem({
    required this.id, required this.type, required this.title, this.body,
    required this.rewardCoins, required this.rewardGems,
    required this.claimed, required this.createdAt, this.expiresAt,
  });

  bool get hasReward => rewardCoins > 0 || rewardGems > 0;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
    id: j['id'] as String,
    type: j['type'] as String? ?? 'announcement',
    title: j['title'] as String,
    body: j['body'] as String?,
    rewardCoins: (j['reward_coins'] as num?)?.toInt() ?? 0,
    rewardGems: (j['reward_gems'] as num?)?.toInt() ?? 0,
    claimed: j['claimed'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    expiresAt: j['expires_at'] != null ? DateTime.parse(j['expires_at'] as String) : null,
  );
}
