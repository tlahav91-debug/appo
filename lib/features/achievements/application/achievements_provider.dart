import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// All defined achievement keys, in display order
const kAllAchievements = [
  {'key': 'first_episode', 'name': 'First Watch',         'icon': '🎬'},
  {'key': 'episodes_10',   'name': 'Binge Starter',       'icon': '📺'},
  {'key': 'episodes_50',   'name': 'Drama Addict',        'icon': '🔥'},
  {'key': 'streak_7',      'name': 'Week Warrior',        'icon': '📅'},
  {'key': 'streak_30',     'name': 'Devoted Fan',         'icon': '💪'},
  {'key': 'first_series',  'name': 'Series Finisher',     'icon': '🏆'},
  {'key': 'series_5',      'name': 'Collection Builder',  'icon': '🌟'},
];

/// Earned achievement keys for any user (public read — achievements are non-sensitive).
final userAchievementsProvider =
    FutureProvider.autoDispose.family<Set<String>, String>((ref, userId) async {
  final data = await Supabase.instance.client
      .from('user_achievements')
      .select('achievement_key')
      .eq('user_id', userId);
  return (data as List)
      .map((r) => (r as Map<String, dynamic>)['achievement_key'] as String)
      .toSet();
});

/// Completed series IDs for the current user (for checkmark overlay on cards).
final seriesCompletionsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  final data = await Supabase.instance.client
      .from('series_completions')
      .select('series_id')
      .eq('user_id', userId);
  return (data as List)
      .map((r) => (r as Map<String, dynamic>)['series_id'] as String)
      .toSet();
});
