import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeriesDetail {
  final String id;
  final String title;
  final String? description;
  final String? genre;
  final String? coverUrl;
  final bool isVip;
  final int totalEpisodes;
  final String? creatorId;

  const SeriesDetail({
    required this.id,
    required this.title,
    this.description,
    this.genre,
    this.coverUrl,
    required this.isVip,
    required this.totalEpisodes,
    this.creatorId,
  });

  factory SeriesDetail.fromJson(Map<String, dynamic> j) => SeriesDetail(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    genre: j['genre'] as String?,
    coverUrl: j['cover_url'] as String?,
    isVip: j['is_vip'] as bool? ?? false,
    totalEpisodes: (j['total_episodes'] as num?)?.toInt() ?? 0,
    creatorId: j['creator_id'] as String?,
  );
}

final seriesDetailProvider = FutureProvider.family<SeriesDetail, String>(
  (ref, seriesId) async {
    final data = await Supabase.instance.client
        .from('series')
        .select('id, title, description, genre, cover_url, is_vip, total_episodes, creator_id')
        .eq('id', seriesId)
        .single();
    return SeriesDetail.fromJson(data as Map<String, dynamic>);
  },
);
