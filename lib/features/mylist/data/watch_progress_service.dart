import 'package:supabase_flutter/supabase_flutter.dart';

class WatchProgressService {
  final _client = Supabase.instance.client;

  // Fire-and-forget — call on 15s heartbeat and on episode end
  void recordProgress(String episodeId, String seriesId, int progressPct, {bool completed = false}) {
    Future.microtask(() async {
      try {
        await _client.functions.invoke('record-watch-progress', body: {
          'episode_id': episodeId,
          'series_id': seriesId,
          'progress_pct': progressPct,
          'completed': completed,
        });
      } catch (_) {}
    });
  }

  Future<List<Map<String, dynamic>>> fetchInProgress() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await _client
        .from('watch_progress')
        .select('*, episodes!episode_id(title, episode_number, series:series_id(title, cover_url))')
        .eq('user_id', userId)
        .eq('completed', false)
        .order('last_watched_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await _client
        .from('watch_progress')
        .select('*, episodes!episode_id(title, episode_number, series:series_id(title, cover_url))')
        .eq('user_id', userId)
        .order('last_watched_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
