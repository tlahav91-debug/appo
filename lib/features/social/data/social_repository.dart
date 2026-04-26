import 'package:supabase_flutter/supabase_flutter.dart';

class SocialRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchFeed() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch activity events from followed users (+ own), last 50, with profile + episode info
    final data = await _client
        .from('activity_events')
        .select('''
          id, created_at, user_id,
          profiles!activity_events_user_id_fkey(username, avatar_url),
          episodes!activity_events_episode_id_fkey(id, title, thumbnail_url),
          series!activity_events_series_id_fkey(id, title),
          activity_likes(user_id),
          activity_comments(id, content, created_at, profiles!activity_comments_user_id_fkey(username))
        ''')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> followUser(String targetId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('user_follows').upsert({
      'follower_id': userId,
      'following_id': targetId,
    });
  }

  Future<void> unfollowUser(String targetId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('user_follows').delete()
        .eq('follower_id', userId)
        .eq('following_id', targetId);
  }

  Future<bool> isFollowing(String targetId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await _client.from('user_follows')
        .select('follower_id')
        .eq('follower_id', userId)
        .eq('following_id', targetId)
        .maybeSingle();
    return res != null;
  }

  Future<void> toggleLike(String eventId, bool currentlyLiked) async {
    final userId = _client.auth.currentUser!.id;
    if (currentlyLiked) {
      await _client.from('activity_likes').delete()
          .eq('user_id', userId).eq('event_id', eventId);
    } else {
      await _client.from('activity_likes').upsert({
        'user_id': userId, 'event_id': eventId,
      });
    }
  }

  Future<void> postComment(String eventId, String content) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('activity_comments').insert({
      'user_id': userId,
      'event_id': eventId,
      'content': content.trim(),
    });
  }

  Future<void> createActivityEvent(String episodeId, String? seriesId) async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    try {
      await _client.functions.invoke('create-activity-event', body: {
        'episode_id': episodeId,
        if (seriesId != null) 'series_id': seriesId,
      });
    } catch (_) {
      // fire-and-forget — ignore errors
    }
  }
}
