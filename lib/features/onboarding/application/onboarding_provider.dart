import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../episodes/domain/episode.dart';
import '../../profile/application/profile_provider.dart';

const _kOnboardingDoneKey = 'onboarding_done';

class OnboardingSeries {
  final String seriesId;
  final Episode firstEpisode;
  const OnboardingSeries({required this.seriesId, required this.firstEpisode});
}

/// True if user has not completed onboarding AND has no genre preferences set.
final shouldShowOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_kOnboardingDoneKey) ?? false;
  if (done) return false;
  final profile = await ref.watch(profileProvider.future);
  return profile.genrePreferences.isEmpty;
});

/// Fetches the flagged onboarding series and its first episode.
final onboardingSeriesProvider = FutureProvider<OnboardingSeries?>((ref) async {
  final data = await Supabase.instance.client
      .from('series')
      .select('id')
      .eq('is_onboarding_series', true)
      .maybeSingle();
  if (data == null) return null;
  final seriesId = data['id'] as String;

  final episodeData = await Supabase.instance.client
      .from('episodes')
      .select()
      .eq('series_id', seriesId)
      .order('episode_number', ascending: true)
      .limit(1)
      .maybeSingle();
  if (episodeData == null) return null;

  return OnboardingSeries(
    seriesId: seriesId,
    firstEpisode: Episode.fromJson(episodeData as Map<String, dynamic>),
  );
});

/// Saves selected genres to Supabase and marks onboarding done locally.
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
