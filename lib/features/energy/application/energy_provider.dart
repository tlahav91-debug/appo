import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/application/profile_provider.dart';
import '../data/watch_episode_service.dart';
import '../domain/watch_result.dart';

final watchEpisodeServiceProvider = Provider<WatchEpisodeService>((ref) {
  return WatchEpisodeService(Supabase.instance.client);
});

final energyStateProvider = Provider<EnergyState>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.when(
    data: (p) => EnergyState(current: p.currentEnergy, lastRefillAt: p.lastRefillAt),
    loading: () => EnergyState(current: 0, lastRefillAt: DateTime.now().toUtc()),
    error: (_, __) => EnergyState(current: 0, lastRefillAt: DateTime.now().toUtc()),
  );
});

class EnergyState {
  final int current;
  final DateTime lastRefillAt;

  const EnergyState({required this.current, required this.lastRefillAt});

  static const int max = 20;

  bool get isFull => current >= max;

  /// Time until the next +1 energy tick. Null if already full.
  Duration? get nextRefillIn {
    if (isFull) return null;
    final nextRefill = lastRefillAt.add(const Duration(hours: 1));
    final remaining = nextRefill.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

final watchEpisodeNotifierProvider =
    AsyncNotifierProvider.autoDispose<WatchEpisodeNotifier, WatchResult?>(
  WatchEpisodeNotifier.new,
);

class WatchEpisodeNotifier extends AutoDisposeAsyncNotifier<WatchResult?> {
  @override
  Future<WatchResult?> build() async => null;

  Future<WatchResult> watch({
    required String episodeId,
    required String requestId,
  }) async {
    state = const AsyncValue.loading();
    final service = ref.read(watchEpisodeServiceProvider);
    final result = await service.watchEpisode(
      episodeId: episodeId,
      requestId: requestId,
    );
    if (result.isSuccess) {
      ref.invalidate(profileProvider);
    }
    state = AsyncValue.data(result);
    return result;
  }
}
