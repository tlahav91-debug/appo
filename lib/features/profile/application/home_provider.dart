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
  final String? genre;
  final int viewCount7d;

  const HomeSeries({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.isVip,
    required this.totalEpisodes,
    this.description,
    this.genre,
    this.viewCount7d = 0,
  });

  factory HomeSeries.fromJson(Map<String, dynamic> j) => HomeSeries(
        id: j['id'] as String,
        title: j['title'] as String,
        coverUrl: j['cover_url'] as String?,
        isVip: j['is_vip'] as bool? ?? false,
        totalEpisodes: (j['total_episodes'] as num?)?.toInt() ?? 0,
        description: j['description'] as String?,
        genre: j['genre'] as String?,
        viewCount7d: (j['view_count_7d'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Top 5 series for the hero carousel, ordered by 7-day view count DESC.
/// If fewer than 5 trending rows exist, pads with newest series.
final featuredSeriesProvider = FutureProvider<List<HomeSeries>>((ref) async {
  final client = Supabase.instance.client;

  final trendingData = await client
      .from('series_trending')
      .select('id, title, cover_url, is_vip, total_episodes, description, genre, view_count_7d')
      .order('view_count_7d', ascending: false)
      .limit(5);

  final trending = (trendingData as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .toList();

  if (trending.length >= 5) return trending;

  // Pad with newest series until we have 5
  final existingIds = trending.map((s) => s.id).toSet();
  final needed = 5 - trending.length;

  final padData = await client
      .from('series')
      .select('id, title, cover_url, is_vip, total_episodes, description, genre')
      .order('created_at', ascending: false)
      .limit(needed + trending.length); // over-fetch to allow dedup

  final padSeries = (padData as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .where((s) => !existingIds.contains(s.id))
      .take(needed)
      .toList();

  return [...trending, ...padSeries];
});

/// All series for the drama grid, ordered by 7-day view count DESC then created_at DESC.
final allSeriesForGridProvider = FutureProvider<List<HomeSeries>>((ref) async {
  final data = await Supabase.instance.client
      .from('series_trending')
      .select('id, title, cover_url, is_vip, total_episodes, genre, view_count_7d');
  return (data as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Top 10 trending series for the Trending Now horizontal row.
final trendingSeriesProvider = FutureProvider<List<HomeSeries>>((ref) async {
  final data = await Supabase.instance.client
      .from('series_trending')
      .select('id, title, cover_url, is_vip, total_episodes, description, genre, view_count_7d')
      .limit(10);
  return (data as List)
      .map((e) => HomeSeries.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// FollowingEpisode model + provider
// ---------------------------------------------------------------------------

/// A single episode entry from a creator the current user follows.
class FollowingEpisode {
  final String submissionId;
  final String episodeTitle;
  final int episodeNumber;
  final String seriesId;
  final String seriesTitle;
  final String? coverUrl;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;

  const FollowingEpisode({
    required this.submissionId,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.seriesId,
    required this.seriesTitle,
    this.coverUrl,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar,
  });

  factory FollowingEpisode.fromJson(Map<String, dynamic> j) => FollowingEpisode(
        submissionId: j['submission_id'] as String,
        episodeTitle: j['episode_title'] as String,
        episodeNumber: (j['episode_number'] as num?)?.toInt() ?? 1,
        seriesId: j['series_id'] as String,
        seriesTitle: j['series_title'] as String,
        coverUrl: j['cover_url'] as String?,
        creatorId: j['creator_id'] as String,
        creatorName: j['creator_name'] as String? ?? 'Creator',
        creatorAvatar: j['creator_avatar'] as String?,
      );
}

/// New episodes from creators the user follows (via RPC fn_new_from_following).
final newFromFollowingProvider = FutureProvider<List<FollowingEpisode>>((ref) async {
  final data = await Supabase.instance.client.rpc('fn_new_from_following');
  return (data as List)
      .map((e) => FollowingEpisode.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// CreatorSpotlight model + provider
// ---------------------------------------------------------------------------

/// Top creator for the spotlight card on the home feed.
class CreatorSpotlight {
  final String id;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int followerCount;
  final int seriesCount;

  const CreatorSpotlight({
    required this.id,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.followerCount,
    required this.seriesCount,
  });

  factory CreatorSpotlight.fromJson(Map<String, dynamic> j) => CreatorSpotlight(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? 'Creator',
        bio: j['bio'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        followerCount: (j['follower_count'] as num?)?.toInt() ?? 0,
        seriesCount: (j['series_count'] as num?)?.toInt() ?? 0,
      );
}

/// Top creator from creator_spotlight view (most-followed with active content).
final creatorSpotlightProvider = FutureProvider<CreatorSpotlight?>((ref) async {
  final data = await Supabase.instance.client
      .from('creator_spotlight')
      .select('id, display_name, bio, avatar_url, follower_count, series_count')
      .limit(1)
      .maybeSingle();
  if (data == null) return null;
  return CreatorSpotlight.fromJson(data as Map<String, dynamic>);
});
