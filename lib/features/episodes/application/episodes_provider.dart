import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/episode_repository.dart';
import '../domain/episode.dart';
import '../domain/episode_choice.dart';
import '../../profile/application/profile_provider.dart';
import '../../energy/data/watch_episode_service.dart';
import '../../energy/domain/watch_result.dart';

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) {
  return EpisodeRepository(Supabase.instance.client);
});

final episodesProvider = FutureProvider.family<List<Episode>, String>(
  (ref, seriesId) => ref.read(episodeRepositoryProvider).fetchEpisodesForSeries(seriesId),
);

final episodeChoicesProvider = FutureProvider.family<List<EpisodeChoice>, String>(
  (ref, episodeId) => ref.read(episodeRepositoryProvider).fetchChoicesForEpisode(episodeId),
);

final episodeUnlockedProvider = FutureProvider.family<bool, String>(
  (ref, episodeId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return Future.value(false);
    return ref.read(episodeRepositoryProvider).isUnlocked(userId, episodeId);
  },
);

// Notifier that handles unlock flow for a single episode
final unlockEpisodeProvider =
    AsyncNotifierProvider.family.autoDispose<UnlockEpisodeNotifier, WatchResult?, String>(
  UnlockEpisodeNotifier.new,
);

class UnlockEpisodeNotifier
    extends AutoDisposeFamilyAsyncNotifier<WatchResult?, String> {
  @override
  Future<WatchResult?> build(String arg) async => null;

  Future<WatchResult> unlock(String requestId) async {
    state = const AsyncValue.loading();
    final service = WatchEpisodeService(Supabase.instance.client);
    final result = await service.watchEpisode(
      episodeId: arg,
      requestId: requestId,
    );
    if (result.isSuccess) {
      ref.invalidate(profileProvider);
      ref.invalidate(episodeUnlockedProvider(arg));
    }
    state = AsyncValue.data(result);
    return result;
  }
}
