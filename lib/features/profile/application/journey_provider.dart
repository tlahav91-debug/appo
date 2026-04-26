import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JourneyStats {
  final int episodesWatched;
  final int currentStreak;
  final int bestRaceRank; // 0 means never raced
  final int savedShows;

  const JourneyStats({
    required this.episodesWatched,
    required this.currentStreak,
    required this.bestRaceRank,
    required this.savedShows,
  });
}

final journeyStatsProvider = FutureProvider<JourneyStats>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return const JourneyStats(
      episodesWatched: 0,
      currentStreak: 0,
      bestRaceRank: 0,
      savedShows: 0,
    );
  }

  final client = Supabase.instance.client;

  // Run all 4 queries concurrently
  final results = await Future.wait([
    // Episodes watched (completed)
    client
        .from('watch_progress')
        .select('id')
        .eq('user_id', userId)
        .eq('completed', true),
    // Latest check-in for streak
    client
        .from('daily_check_ins')
        .select('checked_in_at, streak_day')
        .eq('user_id', userId)
        .order('checked_in_at', ascending: false)
        .limit(1),
    // Best race rank (lowest number = best)
    client
        .from('race_participants')
        .select('rank')
        .eq('user_id', userId)
        .order('rank', ascending: true)
        .limit(1),
    // Saved shows count
    client.from('saved_dramas').select('id').eq('user_id', userId),
  ]);

  final episodesWatched = (results[0] as List).length;

  // Streak: check if last check-in was today or yesterday
  int currentStreak = 0;
  final checkIns = (results[1] as List).cast<Map<String, dynamic>>();
  if (checkIns.isNotEmpty) {
    final lastRow = checkIns.first;
    final lastDate =
        DateTime.parse(lastRow['checked_in_at'] as String).toUtc();
    final lastDay =
        DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
    final today = DateTime.now().toUtc();
    final todayDay = DateTime.utc(today.year, today.month, today.day);
    final yesterday = todayDay.subtract(const Duration(days: 1));
    if (lastDay == todayDay || lastDay == yesterday) {
      currentStreak = (lastRow['streak_day'] as num).toInt();
    }
  }

  final raceRows = (results[2] as List).cast<Map<String, dynamic>>();
  final bestRaceRank =
      raceRows.isNotEmpty ? (raceRows.first['rank'] as num).toInt() : 0;

  final savedShows = (results[3] as List).length;

  return JourneyStats(
    episodesWatched: episodesWatched,
    currentStreak: currentStreak,
    bestRaceRank: bestRaceRank,
    savedShows: savedShows,
  );
});
