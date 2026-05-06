import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakStatus {
  final int currentStreak;    // 0 if never checked in
  final bool claimedToday;
  final List<bool> weekHistory; // 7 booleans, index 0 = day 1

  const StreakStatus({
    required this.currentStreak,
    required this.claimedToday,
    required this.weekHistory,
  });
}

class StreakClaimResult {
  final bool claimed;
  final int streakDay;
  final int coinsEarned;
  final int gemsEarned;
  final String? error;

  const StreakClaimResult({
    required this.claimed,
    required this.streakDay,
    required this.coinsEarned,
    required this.gemsEarned,
    this.error,
  });
}

// Rewards for display in UI (mirrors Edge Function)
const streakRewards = [
  (coins: 20,  gems: 0),
  (coins: 30,  gems: 0),
  (coins: 50,  gems: 2),
  (coins: 75,  gems: 0),
  (coins: 100, gems: 5),
  (coins: 150, gems: 0),
  (coins: 75,  gems: 10),
];

final streakStatusProvider = FutureProvider<StreakStatus>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const StreakStatus(currentStreak: 0, claimedToday: false, weekHistory: [false, false, false, false, false, false, false]);

  final data = await Supabase.instance.client
      .from('daily_check_ins')
      .select('checked_in_at, streak_day')
      .eq('user_id', userId)
      .order('checked_in_at', ascending: false)
      .limit(7);

  final rows = (data as List).cast<Map<String, dynamic>>();

  if (rows.isEmpty) {
    return const StreakStatus(currentStreak: 0, claimedToday: false, weekHistory: [false, false, false, false, false, false, false]);
  }

  final today = DateTime.now().toUtc();
  final todayDate = DateTime.utc(today.year, today.month, today.day);

  bool claimedToday = false;
  int currentStreak = 0;

  // Check if claimed today
  final latestRow = rows.first;
  final latestDate = DateTime.parse(latestRow['checked_in_at'] as String).toUtc();
  final latestDay = DateTime.utc(latestDate.year, latestDate.month, latestDate.day);

  if (latestDay == todayDate) {
    claimedToday = true;
    currentStreak = (latestRow['streak_day'] as num).toInt();
  } else {
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (latestDay == yesterday) {
      currentStreak = (latestRow['streak_day'] as num).toInt();
    }
  }

  // Build week history: indices 0…currentStreak-1 are completed (BUG-027-M-1 fix)
  final weekHistory = List.filled(7, false);
  for (int i = 0; i < currentStreak && i < 7; i++) {
    weekHistory[i] = true;
  }

  return StreakStatus(
    currentStreak: currentStreak,
    claimedToday: claimedToday,
    weekHistory: weekHistory,
  );
});

final streakServiceProvider = Provider((ref) => StreakService());

class StreakService {
  Future<StreakClaimResult> claimDaily() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const StreakClaimResult(claimed: false, streakDay: 0, coinsEarned: 0, gemsEarned: 0, error: 'Not authenticated');

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'claim-daily-streak',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) {
        return StreakClaimResult(claimed: false, streakDay: 0, coinsEarned: 0, gemsEarned: 0, error: data['error'] as String);
      }
      return StreakClaimResult(
        claimed: true,
        streakDay: (data['streak_day'] as num).toInt(),
        coinsEarned: (data['coins_earned'] as num).toInt(),
        gemsEarned: (data['gems_earned'] as num).toInt(),
      );
    } catch (e) {
      return StreakClaimResult(claimed: false, streakDay: 0, coinsEarned: 0, gemsEarned: 0, error: 'Network error');
    }
  }
}
