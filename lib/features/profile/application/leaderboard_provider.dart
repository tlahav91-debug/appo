import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int score; // xp for fan level, episodes_watched for race
  final int? fanLevel;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.score,
    this.fanLevel,
  });
}

// Fan Level leaderboard — top 100 by XP
final fanLevelLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select('id, username, avatar_url, fan_level, xp')
      .order('xp', ascending: false)
      .limit(100);
  final rows = (data as List).cast<Map<String, dynamic>>();
  return rows.asMap().entries.map((e) => LeaderboardEntry(
    userId: e.value['id'] as String,
    username: e.value['username'] as String? ?? 'Player',
    avatarUrl: e.value['avatar_url'] as String?,
    rank: e.key + 1,
    score: (e.value['xp'] as num?)?.toInt() ?? 0,
    fanLevel: (e.value['fan_level'] as num?)?.toInt() ?? 1,
  )).toList();
});

// Weekly leaderboard — top 100 by XP earned this calendar week (Mon–Sun UTC)
final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final data = await Supabase.instance.client.rpc('get_weekly_leaderboard');
  final rows = (data as List).cast<Map<String, dynamic>>();
  return rows.asMap().entries.map((e) => LeaderboardEntry(
    userId: e.value['user_id'] as String,
    username: e.value['username'] as String? ?? 'Player',
    avatarUrl: e.value['avatar_url'] as String?,
    rank: e.key + 1,
    score: (e.value['weekly_xp'] as num?)?.toInt() ?? 0,
    fanLevel: (e.value['fan_level'] as num?)?.toInt() ?? 1,
  )).toList();
});

// Friends leaderboard — fans followed by current user, ranked by all-time XP
final friendsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .rpc('get_friends_leaderboard', params: {'viewer_id': userId});
  final rows = (data as List).cast<Map<String, dynamic>>();
  return rows.asMap().entries.map((e) => LeaderboardEntry(
    userId: e.value['user_id'] as String,
    username: e.value['username'] as String? ?? 'Player',
    avatarUrl: e.value['avatar_url'] as String?,
    rank: e.key + 1,
    score: (e.value['xp'] as num?)?.toInt() ?? 0,
    fanLevel: (e.value['fan_level'] as num?)?.toInt() ?? 1,
  )).toList();
});

// Race leaderboard — top 100 by episodes_watched for the most recent active/ended race
final raceLeaderboardProvider =
    FutureProvider<({String raceTitle, List<LeaderboardEntry> entries})>((ref) async {
  // Get latest race
  final raceData = await Supabase.instance.client
      .from('races')
      .select('id, title')
      .order('starts_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (raceData == null) {
    return (raceTitle: 'No Active Race', entries: <LeaderboardEntry>[]);
  }

  final raceId = raceData['id'] as String;
  final raceTitle = raceData['title'] as String? ?? 'Race';

  final data = await Supabase.instance.client
      .from('race_participants')
      .select('user_id, episodes_watched, profiles(username, avatar_url, fan_level)')
      .eq('race_id', raceId)
      .order('episodes_watched', ascending: false)
      .limit(100);

  final rows = (data as List).cast<Map<String, dynamic>>();
  final entries = rows.asMap().entries.map((e) {
    final profile = e.value['profiles'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      userId: e.value['user_id'] as String,
      username: profile?['username'] as String? ?? 'Player',
      avatarUrl: profile?['avatar_url'] as String?,
      rank: e.key + 1,
      score: (e.value['episodes_watched'] as num?)?.toInt() ?? 0,
      fanLevel: (profile?['fan_level'] as num?)?.toInt() ?? 1,
    );
  }).toList();

  return (raceTitle: raceTitle, entries: entries);
});
