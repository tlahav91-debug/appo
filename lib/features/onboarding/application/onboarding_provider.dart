import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kLaunchCountKey = 'app_launch_count';
const _kOnboardingDoneKey = 'onboarding_done';

/// Returns true if the onboarding quiz should be shown.
/// Condition: launch count == 2 AND onboarding not yet done.
final onboardingGuardProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_kOnboardingDoneKey) ?? false;
  if (done) return false;
  final count = prefs.getInt(_kLaunchCountKey) ?? 0;
  return count == 2;
});

/// Called on every cold start from main.dart / app init.
Future<void> incrementLaunchCount() async {
  final prefs = await SharedPreferences.getInstance();
  final count = (prefs.getInt(_kLaunchCountKey) ?? 0) + 1;
  await prefs.setInt(_kLaunchCountKey, count);
}

/// Saves selected genres to Supabase and marks onboarding done.
Future<void> completeOnboarding(List<String> genres) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
  if (genres.isEmpty) return;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await Supabase.instance.client.from('profiles').update({
    'genre_preferences': genres,
  }).eq('id', userId);
}
