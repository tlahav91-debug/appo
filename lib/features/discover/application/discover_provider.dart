import 'dart:async';

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

// ── Following feed ───────────────────────────────────────────────────────────

final followingFeedProvider = FutureProvider<List<DiscoverSeries>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  // Get creator IDs the user follows
  final follows = await Supabase.instance.client
      .from('creator_follows')
      .select('creator_id')
      .eq('follower_id', userId);

  final creatorIds = (follows as List).map((f) => f['creator_id'] as String).toList();
  if (creatorIds.isEmpty) return [];

  final data = await Supabase.instance.client
      .from('series')
      .select('id, title, description, genre, cover_url, is_vip, total_episodes, created_at')
      .inFilter('creator_id', creatorIds)
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((e) => DiscoverSeries.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Search ───────────────────────────────────────────────────────────────────

class SearchResult {
  final List<DiscoverSeries> series;
  final List<Map<String, dynamic>> creators;
  const SearchResult({required this.series, required this.creators});
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const SearchResult(series: [], creators: []);

  final pattern = '%$query%';

  final seriesData = await Supabase.instance.client
      .from('series')
      .select('id, title, description, genre, cover_url, is_vip, total_episodes, created_at')
      .or('title.ilike.$pattern,genre.ilike.$pattern')
      .order('created_at', ascending: false)
      .limit(20);

  final creatorData = await Supabase.instance.client
      .from('public_creator_profiles')
      .select()
      .or('display_name.ilike.$pattern,bio.ilike.$pattern')
      .limit(10);

  return SearchResult(
    series: (seriesData as List)
        .map((e) => DiscoverSeries.fromJson(e as Map<String, dynamic>))
        .toList(),
    creators: List<Map<String, dynamic>>.from(creatorData as List),
  );
});
