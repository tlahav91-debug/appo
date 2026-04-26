import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Domain model inline (no shared Series model exists yet)
class DiscoverSeries {
  final String id;
  final String title;
  final String? description;
  final String? genre;
  final String? coverUrl;
  final bool isVip;
  final int totalEpisodes;
  final DateTime createdAt;

  const DiscoverSeries({
    required this.id,
    required this.title,
    this.description,
    this.genre,
    this.coverUrl,
    required this.isVip,
    required this.totalEpisodes,
    required this.createdAt,
  });

  factory DiscoverSeries.fromJson(Map<String, dynamic> j) => DiscoverSeries(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    genre: j['genre'] as String?,
    coverUrl: j['cover_url'] as String?,
    isVip: j['is_vip'] as bool? ?? false,
    totalEpisodes: (j['total_episodes'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

// Loads all series once; filtering is done client-side
final allSeriesProvider = FutureProvider<List<DiscoverSeries>>((ref) async {
  final data = await Supabase.instance.client
      .from('series')
      .select('id, title, description, genre, cover_url, is_vip, total_episodes, created_at')
      .order('created_at', ascending: false);
  return (data as List).map((e) => DiscoverSeries.fromJson(e as Map<String, dynamic>)).toList();
});
