import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/episode.dart';
import '../domain/episode_choice.dart';

class EpisodeRepository {
  final SupabaseClient _client;

  EpisodeRepository(this._client);

  Future<List<Episode>> fetchEpisodesForSeries(String seriesId) async {
    final data = await _client
        .from('episodes')
        .select()
        .eq('series_id', seriesId)
        .order('episode_number');
    return (data as List).map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EpisodeChoice>> fetchChoicesForEpisode(String episodeId) async {
    final data = await _client
        .from('episode_choices')
        .select()
        .eq('episode_id', episodeId);
    return (data as List).map((e) => EpisodeChoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> isUnlocked(String userId, String episodeId) async {
    final data = await _client
        .from('episode_unlocks')
        .select('id')
        .eq('user_id', userId)
        .eq('episode_id', episodeId)
        .maybeSingle();
    return data != null;
  }
}
