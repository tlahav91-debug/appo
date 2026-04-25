class RaceParticipant {
  final String userId;
  final String raceId;
  final int episodesWatched;
  final int? rank;
  final DateTime joinedAt;
  final String? username;
  final String? avatarUrl;

  const RaceParticipant({
    required this.userId,
    required this.raceId,
    required this.episodesWatched,
    this.rank,
    required this.joinedAt,
    this.username,
    this.avatarUrl,
  });

  String get displayName => username ?? 'Fan ${userId.substring(0, 6)}';

  factory RaceParticipant.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return RaceParticipant(
      userId: json['user_id'] as String,
      raceId: json['race_id'] as String,
      episodesWatched: (json['episodes_watched'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      joinedAt: DateTime.parse(json['joined_at'] as String).toUtc(),
      // L-2 fix: treat empty string as null so fallback displayName is used
      username: (profile?['username'] as String?)?.isEmpty == true
          ? null
          : profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
