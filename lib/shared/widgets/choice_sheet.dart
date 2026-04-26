import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/collectibles/application/album_provider.dart';
import '../../features/episodes/data/choice_service.dart';
import '../../features/episodes/domain/episode_choice.dart';
import '../../features/profile/application/profile_provider.dart';
import 'coin_toast.dart';
import 'collectible_toast.dart';
import 'level_up_dialog.dart';

class ChoiceSheet extends ConsumerStatefulWidget {
  final String episodeId;
  final List<EpisodeChoice> choices;

  const ChoiceSheet({
    super.key,
    required this.episodeId,
    required this.choices,
  });

  static Future<void> show(
    BuildContext context, {
    required String episodeId,
    required List<EpisodeChoice> choices,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChoiceSheet(episodeId: episodeId, choices: choices),
    );
  }

  @override
  ConsumerState<ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends ConsumerState<ChoiceSheet> {
  String? _loadingChoiceId;
  String? _feedback;
  late final String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = ref.read(choiceServiceProvider).generateIdempotencyKey();
  }

  Future<void> _onChoiceTap(EpisodeChoice choice) async {
    setState(() { _loadingChoiceId = choice.id; _feedback = null; });

    final service = ref.read(choiceServiceProvider);
    final result = await service.recordChoice(
      episodeId: widget.episodeId,
      choiceId: choice.id,
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;

    if (result.success) {
      ref.invalidate(profileProvider);
      if (result.collectibleGranted) {
        ref.invalidate(ownedCollectibleIdsProvider);
      }

      // Show level-up dialog before closing sheet — context still valid here
      if (result.leveledUp && result.newFanLevel != null) {
        final thresholds =
            ref.read(fanLevelThresholdsProvider).valueOrNull ?? [];
        final matches = thresholds.where((t) => t.level == result.newFanLevel);
        final label = matches.isNotEmpty
            ? matches.first.label
            : 'Level ${result.newFanLevel}';
        await LevelUpDialog.show(
          context,
          newLevel: result.newFanLevel!,
          levelLabel: label,
        );
        if (!mounted) return;
      }

      Navigator.pop(context);
      CoinToast.show(context, result.coinsEarned);
      if (result.collectibleGranted && choice.collectibleName != null) {
        // Slight delay so coin toast appears first
        Future.delayed(const Duration(milliseconds: 400), () {
          if (context.mounted) {
            CollectibleToast.show(context, choice.collectibleName!);
          }
        });
      }
    } else {
      setState(() {
        _feedback = result.errorCode == 'EPISODE_LOCKED'
            ? 'Episode is not unlocked.'
            : 'Something went wrong. Please try again.';
        _loadingChoiceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderHi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Choice',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This choice cannot be undone.',
            style: GoogleFonts.sora(color: textDim, fontSize: 12),
          ),
          const SizedBox(height: 20),
          for (final choice in widget.choices) ...[
            _ChoiceButton(
              choice: choice,
              isLoading: _loadingChoiceId == choice.id,
              disabled: _loadingChoiceId != null,
              onTap: () => _onChoiceTap(choice),
            ),
            const SizedBox(height: 10),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 4),
            Text(
              _feedback!,
              style: GoogleFonts.sora(color: pink, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final EpisodeChoice choice;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.choice,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled && !isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: pinkGrad,
            borderRadius: BorderRadius.circular(14),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.label,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '+${choice.rewardCoins} 🪙',
                          style: GoogleFonts.nunito(
                            color: gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        if (choice.collectibleName != null) ...[
                          Text(
                            '  ·  🃏 ${choice.collectibleName}',
                            style: GoogleFonts.nunito(
                              color: purple,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
