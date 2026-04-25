import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/race.dart';
import '../domain/race_participant.dart';

class RaceRepository {
  final _db = Supabase.instance.client;

  Future<Race?> fetchActiveRaceForSeries(String seriesId) async {
    final data = await _db
        .from('races')
        .select()
        .eq('series_id', seriesId)
        .eq('is_active', true)
        .gt('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('ends_at')
        .limit(1)
        .maybeSingle();
    return data == null ? null : Race.fromJson(data);
  }

  Future<Race?> fetchRaceById(String raceId) async {
    final data = await _db
        .from('races')
        .select()
        .eq('id', raceId)
        .maybeSingle();
    return data == null ? null : Race.fromJson(data);
  }

  Future<List<RaceParticipant>> fetchLeaderboard(String raceId) async {
    final rows = await _db
        .from('race_participants')
        .select('*, profiles(username, avatar_url)')
        .eq('race_id', raceId)
        .order('episodes_watched', ascending: false)
        .order('joined_at') // tiebreaker: earlier joiner ranks higher
        .limit(50);
    return rows.map<RaceParticipant>(RaceParticipant.fromJson).toList();
  }

  Stream<List<RaceParticipant>> leaderboardStream(String raceId) async* {
    yield await fetchLeaderboard(raceId);

    final ctrl = StreamController<void>.broadcast();
    final channel = _db.channel('race_lb_$raceId');

    // C-3 fix: subscribe inside try so finally always cleans up
    try {
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'race_participants',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'race_id',
              value: raceId,
            ),
            callback: (_) => ctrl.add(null),
          )
          .subscribe();

      await for (final _ in ctrl.stream) {
        yield await fetchLeaderboard(raceId);
      }
    } finally {
      await ctrl.close();
      _db.removeChannel(channel);
    }
  }

  Future<bool> isParticipant(String raceId, String userId) async {
    final data = await _db
        .from('race_participants')
        .select('user_id')
        .eq('race_id', raceId)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null;
  }

  // C-2 fix: check FunctionResponse status and throw on failure
  Future<void> joinRace(String raceId) async {
    final res = await _db.functions.invoke('join-race', body: {'race_id': raceId});
    if (res.status != 200) {
      throw Exception('Failed to join race (${res.status}): ${res.data}');
    }
  }
}
