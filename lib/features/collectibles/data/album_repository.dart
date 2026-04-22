import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/album.dart';
import '../domain/collectible.dart';

class AlbumRepository {
  final SupabaseClient _client;

  AlbumRepository(this._client);

  Future<Album?> fetchAlbumForSeries(String seriesId) async {
    final data = await _client
        .from('albums')
        .select()
        .eq('series_id', seriesId)
        .maybeSingle();
    return data == null ? null : Album.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Collectible>> fetchCollectiblesForSeries(String seriesId) async {
    final data = await _client
        .from('collectibles')
        .select()
        .eq('series_id', seriesId)
        .order('episode_id');
    return (data as List)
        .map((e) => Collectible.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchOwnedCollectibleIds(String userId) async {
    final data = await _client
        .from('user_collectibles')
        .select('collectible_id')
        .eq('user_id', userId);
    return {
      for (final row in data as List) row['collectible_id'] as String,
    };
  }
}
