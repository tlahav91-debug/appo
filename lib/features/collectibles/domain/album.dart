class Album {
  final String id;
  final String seriesId;
  final String name;
  final int totalCards;

  const Album({
    required this.id,
    required this.seriesId,
    required this.name,
    required this.totalCards,
  });

  factory Album.fromJson(Map<String, dynamic> j) => Album(
        id: j['id'] as String,
        seriesId: j['series_id'] as String,
        name: j['name'] as String,
        totalCards: (j['total_cards'] as num).toInt(),
      );
}
