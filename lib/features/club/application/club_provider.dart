import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/club_repository.dart';
import '../domain/club_member.dart';
import '../domain/watch_club.dart';

final clubRepositoryProvider =
    Provider<ClubRepository>((_) => ClubRepository());

final userClubProvider = FutureProvider<WatchClub?>((ref) {
  return ref.read(clubRepositoryProvider).fetchUserClub();
});

final clubLeaderboardProvider =
    StreamProvider.family<List<ClubMember>, String>((ref, clubId) {
  return ref.read(clubRepositoryProvider).leaderboardStream(clubId);
});

final clubSearchProvider =
    FutureProvider.family<List<WatchClub>, String>((ref, query) {
  final repo = ref.read(clubRepositoryProvider);
  return query.isEmpty ? repo.fetchTopClubs() : repo.searchClubs(query);
});

class ClubActionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> create(String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      final id = await ref.read(clubRepositoryProvider).createClub(name, description);
      ref.invalidate(userClubProvider);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> join(String clubId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(clubRepositoryProvider).joinClub(clubId);
      ref.invalidate(userClubProvider);
      ref.invalidate(clubSearchProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> leave(String clubId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(clubRepositoryProvider).leaveClub(clubId);
      ref.invalidate(userClubProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final clubActionProvider =
    AsyncNotifierProvider.autoDispose<ClubActionNotifier, void>(
  ClubActionNotifier.new,
);
