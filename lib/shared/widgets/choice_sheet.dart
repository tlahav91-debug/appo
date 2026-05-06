import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/analytics/analytics_provider.dart';
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

  Future<void> _onPremiumChoiceTap(EpisodeChoice choice) async {
    final profile = ref.read(profileProvider).valueOrNull;
    final balance = profile?.coins ?? 0;
    final cost = choice.premiumCoinCost;

    if (balance < cost) {
      final deficit = cost - balance;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need $deficit more 🪙 — watch an ad or buy coins')),
      );
      return;
    }

    setState(() { _loadingChoiceId = choice.id; _feedback = null; });
    final messenger = ScaffoldMessenger.of(context);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() { _loadingChoiceId = null; });
        return;
      }
      final requestId = '${choice.id}:${DateTime.now().millisecondsSinceEpoch}';
      final res = await Supabase.instance.client.functions.invoke(
        'record-premium-choice',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {
          'episode_id': widget.episodeId,
          'choice_id': choice.id,
          'request_id': requestId,
        },
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>;
      if (data['choice_recorded'] == true) {
        ref.invalidate(profileProvider);
        ref.read(analyticsProvider).capture('premium_choice_made', properties: {
          'episode_id': widget.episodeId,
          'choice_id': choice.id,
          'coins_spent': data['coins_spent'],
        });
        Navigator.pop(context);
      }
    } on FunctionException catch (fe) {
      if (!mounted) return;
      final body = fe.details;
      if (fe.status == 402 && body is Map && body['code'] == 'INSUFFICIENT_COINS') {
        final required = (body['required'] as num?)?.toInt() ?? cost;
        final current = (body['current'] as num?)?.toInt() ?? 0;
        final deficit = required - current;
        messenger.showSnackBar(
          SnackBar(content: Text('Need $deficit more 🪙 — watch an ad or buy coins')),
        );
      } else if (fe.status == 409) {
        setState(() { _feedback = 'Balance changed — please retry.'; });
      } else {
        setState(() { _feedback = 'Something went wrong. Please try again.'; });
      }
      if (mounted) setState(() { _loadingChoiceId = null; });
    } catch (e) {
      if (mounted) setState(() { _feedback = 'Error. Please try again.'; _loadingChoiceId = null; });
    }
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

      ref.read(analyticsProvider).capture('choice_made', properties: {
        'episode_id': widget.episodeId,
        'choice_id': choice.id,
        'coins_earned': result.coinsEarned,
        'xp_gained': result.xpGained,
      });

      // Show level-up dialog before closing sheet — context still valid here
      if (result.leveledUp && result.newFanLevel != null) {
        ref.read(analyticsProvider).capture('level_up', properties: {
          'new_fan_level': result.newFanLevel,
          'source': 'episode',
        });
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
          for (final choice in widget.choices.where((c) => c.isPremium)) ...[
            _PremiumChoiceButton(
              choice: choice,
              isLoading: _loadingChoiceId == choice.id,
              disabled: _loadingChoiceId != null,
              onTap: () => _onPremiumChoiceTap(choice),
            ),
            const SizedBox(height: 10),
          ],
          for (final choice in widget.choices.where((c) => !c.isPremium)) ...[
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

class _PremiumChoiceButton extends StatelessWidget {
  final EpisodeChoice choice;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _PremiumChoiceButton({
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
          decoration: BoxDecoration(
            gradient: goldGrad,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: goldGrad,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: GoogleFonts.nunito(
                            color: bgDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        choice.label,
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🪙 ${choice.premiumCoinCost}',
                        style: GoogleFonts.nunito(
                          color: gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
