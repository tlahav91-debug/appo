import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/club_member.dart';
import '../domain/watch_club.dart';

class ClubRepository {
  final _db = Supabase.instance.client;

  Future<WatchClub?> fetchUserClub() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;

    final membership = await _db
        .from('watch_club_members')
        .select('club_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null) return null;
    return fetchClub(membership['club_id'] as String);
  }

  Future<WatchClub?> fetchClub(String clubId) async {
    final data = await _db
        .from('watch_clubs')
        .select()
        .eq('id', clubId)
        .maybeSingle();
    return data == null ? null : WatchClub.fromJson(data);
  }

  Future<List<WatchClub>> searchClubs(String query) async {
    final rows = await _db
        .from('watch_clubs')
        .select()
        .ilike('name', '%$query%')
        .order('member_count', ascending: false)
        .limit(30);
    return rows.map<WatchClub>(WatchClub.fromJson).toList();
  }

  Future<List<WatchClub>> fetchTopClubs() async {
    final rows = await _db
        .from('watch_clubs')
        .select()
        .order('member_count', ascending: false)
        .limit(30);
    return rows.map<WatchClub>(WatchClub.fromJson).toList();
  }

  Future<List<ClubMember>> fetchLeaderboard(String clubId) async {
    final club = await fetchClub(clubId);
    if (club == null) return [];

    final rows = await _db.rpc(
      'club_weekly_leaderboard',
      params: {'p_club_id': clubId},
    ) as List;

    return rows
        .map((r) => ClubMember.fromRpc(r as Map<String, dynamic>, club.ownerId))
        .toList();
  }

  Stream<List<ClubMember>> leaderboardStream(String clubId) async* {
    yield await fetchLeaderboard(clubId);

    final ctrl = StreamController<void>.broadcast();

    try {
      final channel = _db.channel('club_members_$clubId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'watch_club_members',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (_) => ctrl.add(null),
          )
          .subscribe();

      try {
        await for (final _ in ctrl.stream) {
          yield await fetchLeaderboard(clubId);
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

  Future<String> createClub(String name, String? description) async {
    final result = await _db.rpc('create_club', params: {
      'p_name': name,
      'p_description': description,
    });
    return result as String;
  }

  Future<void> joinClub(String clubId) async {
    await _db.rpc('join_club', params: {'p_club_id': clubId});
  }

  Future<void> leaveClub(String clubId) async {
    await _db.rpc('leave_club', params: {'p_club_id': clubId});
  }
}
