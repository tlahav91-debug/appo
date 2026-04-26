import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// HomeSeries model
// ---------------------------------------------------------------------------
class HomeSeries {
  final String id;
  final String title;
  final String? coverUrl;
  final bool isVip;
  final int totalEpisodes;
  final String? description;

  const HomeSeries({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.isVip,
    required this.totalEpisodes,
    this.description,
  });

  factory HomeSeries.fromJson(Map<String, dynamic> j) => HomeSeries(
        id: j['id'] as String,
        title: j['title'] as String,
        coverUrl: j['cover_url'] as String?,
        isVip: j['is_vip'] as bool? ?? false,
        totalEpisodes: (j['total_episodes'] as num?)?.toInt() ?? 0,
        description: j['description'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Top 5 series for the hero carousel, ordered by created_at DESC.
final featuredSeriesProvider = FutureProvider<List<HomeSeries>>((ref) async {
  final data = await Supabase.instance.client
      .from('series')
      .select('id, title, cover_url, is_vip, total_episodes, description')
      .order('created_at', ascending: false)
      .limit(5);
  return (data as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// All series for the drama grid, ordered by created_at DESC.
final allSeriesForGridProvider = FutureProvider<List<HomeSeries>>((ref) async {
  final data = await Supabase.instance.client
      .from('series')
      .select('id, title, cover_url, is_vip, total_episodes')
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .toList();
});
