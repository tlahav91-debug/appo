class Character {
  final String id;
  final String seriesId;
  final String name;
  final String? avatarUrl;
  final int affinityThreshold1;
  final int affinityThreshold2;

  const Character({
    required this.id,
    required this.seriesId,
    required this.name,
    this.avatarUrl,
    required this.affinityThreshold1,
    required this.affinityThreshold2,
  });

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        seriesId: json['series_id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        affinityThreshold1:
            (json['affinity_threshold_1'] as num?)?.toInt() ?? 10,
        affinityThreshold2:
            (json['affinity_threshold_2'] as num?)?.toInt() ?? 25,
      );
}
