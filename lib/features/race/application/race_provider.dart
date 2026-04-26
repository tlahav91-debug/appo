import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../data/race_repository.dart';
import '../domain/race.dart';
import '../domain/race_participant.dart';

final raceRepositoryProvider = Provider<RaceRepository>((_) => RaceRepository());

// H-2 fix: ref.watch so provider rebuilds if repository ever changes
final activeRaceProvider = FutureProvider.family<Race?, String>((ref, seriesId) {
  return ref.watch(raceRepositoryProvider).fetchActiveRaceForSeries(seriesId);
});

final raceByIdProvider = FutureProvider.family<Race?, String>((ref, raceId) {
  return ref.watch(raceRepositoryProvider).fetchRaceById(raceId);
});

final raceLeaderboardProvider =
    StreamProvider.family<List<RaceParticipant>, String>((ref, raceId) {
  return ref.watch(raceRepositoryProvider).leaderboardStream(raceId);
});

final raceParticipantProvider =
    FutureProvider.family<bool, String>((ref, raceId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  return ref.watch(raceRepositoryProvider).isParticipant(raceId, userId);
});

// M-5 fix: family so each race gets its own join notifier
class RaceJoinNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> join() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(raceRepositoryProvider).joinRace(arg);
      ref.read(analyticsProvider).capture('race_joined', properties: {'race_id': arg});
      ref.invalidate(raceParticipantProvider(arg));
      ref.invalidate(raceLeaderboardProvider(arg));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final raceJoinProvider =
    AsyncNotifierProvider.autoDispose.family<RaceJoinNotifier, void, String>(
  RaceJoinNotifier.new,
);
