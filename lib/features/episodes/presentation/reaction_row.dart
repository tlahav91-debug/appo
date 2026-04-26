import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/reaction_provider.dart';

class ReactionRow extends ConsumerWidget {
  final String episodeId;

  const ReactionRow({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(episodeReactionProvider(episodeId));

    return stateAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) => _ReactionBar(
        episodeId: episodeId,
        state: state,
        onReact: (reaction) async {
          final isSame = state.myReaction == reaction;
          // Optimistic update: invalidate and reload
          if (isSame) {
            await ref.read(reactionServiceProvider).removeReaction(episodeId);
          } else {
            await ref.read(reactionServiceProvider).react(episodeId, reaction);
          }
          ref.invalidate(episodeReactionProvider(episodeId));
        },
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  final String episodeId;
  final EpisodeReactionState state;
  final Future<void> Function(String) onReact;

  const _ReactionBar({required this.episodeId, required this.state, required this.onReact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reactions', style: GoogleFonts.nunito(color: textDim, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: kReactions.map((emoji) {
            final count = state.counts[emoji] ?? 0;
            final isSelected = state.myReaction == emoji;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onReact(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? pink.withOpacity(0.2) : surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? pink : border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: GoogleFonts.nunito(
                            color: isSelected ? pink : textDim,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
