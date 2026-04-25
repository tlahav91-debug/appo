import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/character.dart';
import '../domain/character_affinity.dart';

class AffinityRepository {
  final _db = Supabase.instance.client;

  Future<bool> seriesHasCharacters(String seriesId) async {
    final rows = await _db
        .from('characters')
        .select('id')
        .eq('series_id', seriesId)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<List<CharacterAffinity>> fetchAffinityForSeries(String seriesId) async {
    final userId = _db.auth.currentUser?.id;

    final chars = await _db
        .from('characters')
        .select()
        .eq('series_id', seriesId)
        .order('name');

    if (chars.isEmpty) return [];

    Map<String, int> affinityMap = {};
    if (userId != null) {
      final charIds = chars.map((c) => c['id'] as String).toList();
      final rows = await _db
          .from('character_affinity')
          .select('character_id, affinity_points')
          .eq('user_id', userId)
          .inFilter('character_id', charIds);
      for (final r in rows) {
        affinityMap[r['character_id'] as String] =
            (r['affinity_points'] as num).toInt();
      }
    }

    return chars.map((c) {
      final character = Character.fromJson(c);
      return CharacterAffinity(
        character: character,
        affinityPoints: affinityMap[character.id] ?? 0,
      );
    }).toList();
  }

  Stream<List<CharacterAffinity>> affinityStream(String seriesId) async* {
    yield await fetchAffinityForSeries(seriesId);

    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    final ctrl = StreamController<void>.broadcast();

    // C-1 fix: channel created inside try so finally always cleans up
    try {
      final channel = _db.channel('affinity_${userId}_$seriesId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'character_affinity',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) => ctrl.add(null),
          )
          .subscribe();

      try {
        await for (final _ in ctrl.stream) {
          yield await fetchAffinityForSeries(seriesId);
        }
      } finally {
        await ctrl.close();
        _db.removeChannel(channel);
      }
    } catch (_) {
      await ctrl.close();
      rethrow;
    }
  }
}
