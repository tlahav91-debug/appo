class ClubMember {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final int episodesThisWeek;
  final bool isOwner;

  const ClubMember({
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.episodesThisWeek,
    required this.isOwner,
  });

  String get displayName => username ?? 'Fan ${userId.substring(0, 6)}';

  factory ClubMember.fromRpc(Map<String, dynamic> json, String ownerId) =>
      ClubMember(
        userId: json['user_id'] as String,
        username: (json['username'] as String?)?.isEmpty == true
            ? null
            : json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        episodesThisWeek: (json['episodes_this_week'] as num?)?.toInt() ?? 0,
        isOwner: json['user_id'] as String == ownerId,
      );
}
