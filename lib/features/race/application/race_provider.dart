import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/race_repository.dart';
import '../domain/race.dart';
import '../domain/race_participant.dart';

final raceRepositoryProvider = Provider<RaceRepository>((_) => RaceRepository());

final activeRaceProvider = FutureProvider.family<Race?, String>((ref, seriesId) {
  return ref.read(raceRepositoryProvider).fetchActiveRaceForSeries(seriesId);
});

final raceByIdProvider = FutureProvider.family<Race?, String>((ref, raceId) {
  return ref.read(raceRepositoryProvider).fetchRaceById(raceId);
});

final raceLeaderboardProvider =
    StreamProvider.family<List<RaceParticipant>, String>((ref, raceId) {
  return ref.read(raceRepositoryProvider).leaderboardStream(raceId);
});

final raceParticipantProvider =
    FutureProvider.family<bool, String>((ref, raceId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  return ref.read(raceRepositoryProvider).isParticipant(raceId, userId);
});

class RaceJoinNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> join(String raceId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(raceRepositoryProvider).joinRace(raceId);
      ref.invalidate(raceParticipantProvider(raceId));
      ref.invalidate(raceLeaderboardProvider(raceId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final raceJoinProvider =
    AsyncNotifierProvider.autoDispose<RaceJoinNotifier, void>(RaceJoinNotifier.new);
