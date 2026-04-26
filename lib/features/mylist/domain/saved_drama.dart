class SavedDrama {
  final String id;
  final String seriesId;
  final DateTime savedAt;

  const SavedDrama({
    required this.id,
    required this.seriesId,
    required this.savedAt,
  });

  factory SavedDrama.fromJson(Map<String, dynamic> j) => SavedDrama(
    id: j['id'] as String,
    seriesId: j['series_id'] as String,
    savedAt: DateTime.parse(j['saved_at'] as String),
  );
}
