import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kReactions = ['🔥', '❤️', '😱', '😢', '👏', '😂', '🤯', '💔', '👀', '😍', '💜', '⚡'];

class EpisodeReactionState {
  final Map<String, int> counts;   // emoji → count
  final String? myReaction;        // null if not reacted

  const EpisodeReactionState({required this.counts, this.myReaction});

  EpisodeReactionState copyWith({Map<String, int>? counts, String? myReaction, bool clearMyReaction = false}) =>
    EpisodeReactionState(
      counts: counts ?? this.counts,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    );
}

final episodeReactionProvider =
    FutureProvider.family<EpisodeReactionState, String>((ref, episodeId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final client = Supabase.instance.client;

  // Get all reactions for this episode
  final data = await client
      .from('episode_reactions')
      .select('reaction, user_id')
      .eq('episode_id', episodeId);

  final rows = (data as List).cast<Map<String, dynamic>>();
  final counts = <String, int>{for (final r in kReactions) r: 0};
  String? myReaction;

  for (final row in rows) {
    final r = row['reaction'] as String;
    counts[r] = (counts[r] ?? 0) + 1;
    if (userId != null && row['user_id'] == userId) myReaction = r;
  }

  return EpisodeReactionState(counts: counts, myReaction: myReaction);
});

final reactionServiceProvider = Provider((ref) => ReactionService());

class ReactionService {
  Future<void> react(String episodeId, String reaction) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('episode_reactions').upsert({
      'user_id': userId,
      'episode_id': episodeId,
      'reaction': reaction,
    }, onConflict: 'user_id,episode_id');
  }

  Future<void> removeReaction(String episodeId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('episode_reactions')
        .delete()
        .eq('user_id', userId)
        .eq('episode_id', episodeId);
  }
}
