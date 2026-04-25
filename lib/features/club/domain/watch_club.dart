class WatchClub {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final int memberCount;
  final DateTime createdAt;

  const WatchClub({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.memberCount,
    required this.createdAt,
  });

  factory WatchClub.fromJson(Map<String, dynamic> json) => WatchClub(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        ownerId: json['owner_id'] as String,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
        createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      );
}
