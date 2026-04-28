class EpisodeComment {
  final String id;
  final String episodeId;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final String body;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const EpisodeComment({
    required this.id,
    required this.episodeId,
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.body,
    this.deletedAt,
    required this.createdAt,
  });

  bool get isDeleted => deletedAt != null;

  factory EpisodeComment.fromJson(Map<String, dynamic> j) => EpisodeComment(
        id: j['id'] as String,
        episodeId: j['episode_id'] as String,
        userId: j['user_id'] as String,
        username: j['profiles']?['username'] as String?,
        avatarUrl: j['profiles']?['avatar_url'] as String?,
        body: j['body'] as String,
        deletedAt: j['deleted_at'] != null
            ? DateTime.parse(j['deleted_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
