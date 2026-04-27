import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/social_repository.dart';

final socialRepositoryProvider = Provider((ref) => SocialRepository());

final socialFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(socialRepositoryProvider).fetchFeed();
});

final followStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return ref.read(socialRepositoryProvider).isFollowing(userId);
});

// NOTE: positional arg pattern — valid in Riverpod 2.x manual providers; not code-gen compatible
class FollowNotifier extends AutoDisposeAsyncNotifier<bool> {
  final String targetId;
  FollowNotifier(this.targetId);

  @override
  Future<bool> build() async {
    return ref.read(socialRepositoryProvider).isFollowing(targetId);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    state = const AsyncLoading();
    if (current) {
      await ref.read(socialRepositoryProvider).unfollowUser(targetId);
    } else {
      await ref.read(socialRepositoryProvider).followUser(targetId);
    }
    state = AsyncData(!current);
  }
}

final followNotifierProvider = AutoDisposeAsyncNotifierProvider.family<FollowNotifier, bool, String>(
  (targetId) => FollowNotifier(targetId),
);
