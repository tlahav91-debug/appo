import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lava_quest_repository.dart';
import '../domain/lava_quest.dart';

final lavaQuestRepositoryProvider =
    Provider<LavaQuestRepository>((_) => LavaQuestRepository());

final activeQuestsProvider = StreamProvider<List<LavaQuest>>((ref) {
  return ref.watch(lavaQuestRepositoryProvider).activeQuestsStream();
});

final questByIdProvider = FutureProvider.family<LavaQuest?, String>((ref, questId) {
  return ref.watch(lavaQuestRepositoryProvider).fetchQuestById(questId);
});

class QuestClaimNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<Map<String, int>> claim() async {
    state = const AsyncValue.loading();
    try {
      final result =
          await ref.read(lavaQuestRepositoryProvider).claimReward(arg);
      ref.invalidate(activeQuestsProvider);
      ref.invalidate(questByIdProvider(arg));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final questClaimProvider =
    AsyncNotifierProvider.autoDispose.family<QuestClaimNotifier, void, String>(
  QuestClaimNotifier.new,
);
