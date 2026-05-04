import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dailyRewardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = Supabase.instance.client;
  final userId = db.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');

  final results = await Future.wait([
    db
        .from('daily_reward_cycles')
        .select('cycle_day, last_claimed_at')
        .eq('user_id', userId)
        .maybeSingle(),
    db
        .from('daily_check_ins')
        .select('checked_in_at')
        .eq('user_id', userId)
        .order('checked_in_at', ascending: false)
        .limit(60),
  ]);

  final cycleRow = results[0] as Map<String, dynamic>?;
  final checkIns = results[1] as List<dynamic>;

  final cycleDay = (cycleRow?['cycle_day'] as num?)?.toInt() ?? 1;
  final lastClaimedAt = cycleRow?['last_claimed_at'] as String?;
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final claimedToday =
      lastClaimedAt != null && lastClaimedAt.substring(0, 10) == today;

  final streak = _computeStreak(checkIns);

  return {
    'cycle_day': cycleDay,
    'claimed_today': claimedToday,
    'streak': streak,
  };
});

int _computeStreak(List<dynamic> checkIns) {
  if (checkIns.isEmpty) return 0;
  final dates = checkIns
      .map((c) => (c as Map<String, dynamic>)['checked_in_at'] as String)
      .map((s) => s.substring(0, 10))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final yesterday = DateTime.now()
      .toUtc()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);
  if (dates.first != today && dates.first != yesterday) return 0;
  int streak = 1;
  for (int i = 1; i < dates.length; i++) {
    final prev = DateTime.parse(dates[i - 1]);
    final curr = DateTime.parse(dates[i]);
    if (prev.difference(curr).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
