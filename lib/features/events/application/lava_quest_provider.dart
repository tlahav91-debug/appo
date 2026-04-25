import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lava_quest_repository.dart';
import '../domain/lava_quest.dart';

final lavaQuestRepositoryProvider =
    Provider<LavaQuestRepository>((_) => LavaQuestRepository());

final activeQuestsProvider = StreamProvider<List<LavaQuest>>((ref) {
  return ref.watch(lavaQuestRepositoryProvider).activeQuestsStream();
});

// BUG-006: derive from the live stream so progress updates automatically
final questByIdProvider = Provider.family<AsyncValue<LavaQuest?>, String>((ref, questId) {
  final streamValue = ref.watch(activeQuestsProvider);
  return streamValue.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (quests) {
      final match = quests.where((q) => q.id == questId).firstOrNull;
      return AsyncValue.data(match);
    },
  );
});

class QuestClaimNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<Map<String, dynamic>> claim() async {
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
