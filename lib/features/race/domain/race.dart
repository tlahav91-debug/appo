class Race {
  final String id;
  final String seriesId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  const Race({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  factory Race.fromJson(Map<String, dynamic> json) => Race(
        id: json['id'] as String,
        seriesId: json['series_id'] as String,
        title: json['title'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
        endsAt: DateTime.parse(json['ends_at'] as String).toUtc(),
        isActive: json['is_active'] as bool? ?? true,
      );

  bool get isLive => isActive && endsAt.isAfter(DateTime.now().toUtc());

  Duration get timeRemaining {
    final diff = endsAt.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }
}
