import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/g_btn.dart';
import '../../../shared/widgets/energy_timer.dart';
import '../../ads/application/ad_provider.dart';
import '../../episodes/application/episode_progress_provider.dart';
import '../../episodes/domain/episode.dart';
import '../../profile/application/profile_provider.dart';
import '../application/energy_provider.dart';
import '../data/watch_episode_service.dart';

class EnergyGate extends ConsumerStatefulWidget {
  final int currentEnergy;
  final Episode? episode;

  const EnergyGate({super.key, required this.currentEnergy, this.episode});

  static Future<void> show(
    BuildContext context, {
    required int currentEnergy,
    Episode? episode,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EnergyGate',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) =>
          EnergyGate(currentEnergy: currentEnergy, episode: episode),
    );
  }

  @override
  ConsumerState<EnergyGate> createState() => _EnergyGateState();
}

class _EnergyGateState extends ConsumerState<EnergyGate> {
  bool _adLoading = false;
  bool _gemLoading = false;
  bool _coinLoading = false;
  String? _feedback;

  Future<void> _claimAdReward() async {
    setState(() { _adLoading = true; _feedback = null; });

    final adService = ref.read(adServiceProvider);
    final adResult = await adService.showAd();

    if (!mounted) return;

    if (adResult == AdShowResult.dismissed) {
      setState(() {
        _feedback = 'Watch the full ad to earn energy.';
        _adLoading = false;
      });
      return;
    }

    if (adResult != AdShowResult.rewarded) {
      setState(() {
        _feedback = 'Ad not available right now. Try again later.';
        _adLoading = false;
      });
      return;
    }

    // Ad fully watched — credit server-side
    final service = ref.read(watchEpisodeServiceProvider);
    final result = await service.claimAdReward(rewardType: 'energy');
    if (!mounted) return;

    if (result.success) {
      ref.invalidate(profileProvider);
      setState(() => _feedback = '+2 energy earned!');
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _feedback = result.error == AdRewardError.capReached
          ? 'You\'ve claimed all 5 free ads for today.'
          : 'Reward failed. Please try again.');
    }
    if (mounted) setState(() => _adLoading = false);
  }

  Future<void> _coinUnlock() async {
    final ep = widget.episode;
    if (ep == null) return;
    setState(() { _coinLoading = true; _feedback = null; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) { setState(() => _coinLoading = false); return; }
      final requestId = '${ep.id}:${DateTime.now().millisecondsSinceEpoch}';
      final res = await Supabase.instance.client.functions.invoke(
        'unlock-episode-coins',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'episode_id': ep.id, 'request_id': requestId},
      );
      final data = res.data as Map<String, dynamic>;
      if (!mounted) return;
      if (data['unlocked'] == true) {
        ref.invalidate(episodeUnlockedProvider(ep.id));
        ref.invalidate(profileProvider);
        final router = GoRouter.of(context);
        Navigator.pop(context);
        router.push('/series/${ep.seriesId}/episode/${ep.id}', extra: ep);
      } else if (data['code'] == 'INSUFFICIENT_COINS') {
        setState(() {
          _feedback = 'Not enough coins (need ${data['required']} 🪙).';
          _coinLoading = false;
        });
      } else {
        setState(() { _feedback = 'Unlock failed. Try again.'; _coinLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _feedback = 'Error: $e'; _coinLoading = false; });
    }
  }

  Future<void> _claimGemRefill() async {
    setState(() { _gemLoading = true; _feedback = null; });
    final service = ref.read(watchEpisodeServiceProvider);
    final result = await service.claimGemRefill();
    if (!mounted) return;

    if (result.success) {
      ref.invalidate(profileProvider);
      Navigator.pop(context);
    } else {
      setState(() => _feedback = switch (result.error) {
        GemRefillError.insufficientGems => 'Not enough gems.',
        GemRefillError.energyFull => 'Your energy is already full!',
        _ => 'Refill failed. Please try again.',
      });
    }
    if (mounted) setState(() => _gemLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final energy = ref.watch(energyStateProvider);
    final adReady = ref.watch(adServiceProvider).isReady;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgDeep, surface],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: textDim, size: 24),
                  ),
                ),
                const SizedBox(height: 8),

                // Dramatic header
                const Text('⚡', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  'Out of Energy',
                  style: GoogleFonts.nunito(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You need more ⚡ to keep watching',
                  style: GoogleFonts.sora(color: textSec, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Current energy row
                Text(
                  '${energy.current} / ${EnergyState.max} ⚡',
                  style: GoogleFonts.nunito(color: textDim, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const EnergyTimer(),
                const Divider(color: border, height: 32),

                // Option 1 — Watch Ad
                GBtn(
                  gradient: adReady ? greenGrad : darkGrad,
                  width: double.infinity,
                  onPressed: (_adLoading || !adReady) ? null : _claimAdReward,
                  child: _adLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: textCol),
                        )
                      : Text(
                          adReady ? 'Watch an Ad · Get 2 ⚡ free' : 'Ad loading…',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
                const SizedBox(height: 10),

                // Option 2 — Gem Refill
                GBtn(
                  gradient: purpleGrad,
                  width: double.infinity,
                  onPressed: _gemLoading ? null : _claimGemRefill,
                  child: _gemLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: textCol),
                        )
                      : Text(
                          'Refill to Full · 50 💎',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
                const SizedBox(height: 10),

                // Option 3 — Coin Unlock (only shown when episode has a coin cost)
                if (widget.episode != null && widget.episode!.coinCost > 0) ...[
                  GBtn(
                    gradient: goldGrad,
                    width: double.infinity,
                    onPressed: _coinLoading ? null : _coinUnlock,
                    child: _coinLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: textCol),
                          )
                        : Text(
                            'Unlock for 🪙 ${widget.episode!.coinCost} coins',
                            style: GoogleFonts.nunito(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Option 4 — Get Gems
                GBtn(
                  gradient: darkGrad,
                  width: double.infinity,
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push('/shop/gems');
                  },
                  child: Text(
                    'Get Gems',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Option 4 — Watch rewarded ad for +5 energy (PRD-038)
                _AdButton(onDismiss: () => Navigator.pop(context)),
                const SizedBox(height: 10),

                // Option 5 — Wait
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Wait for free energy',
                    style: GoogleFonts.sora(color: textDim, fontSize: 14),
                  ),
                ),

                // Feedback
                if (_feedback != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _feedback!,
                    style: GoogleFonts.sora(color: pink, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Drama Pass promo
                const SizedBox(height: 8),
                Text(
                  'Drama Pass members get +5 energy daily',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRD-038: Gold "Watch ad for +5⚡" button — shown only when ad is ready and
// the user has not yet hit the daily cap (3 grants per calendar day).
// ---------------------------------------------------------------------------
class _AdButton extends ConsumerWidget {
  final VoidCallback onDismiss;

  const _AdButton({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capAsync = ref.watch(adEnergyCapProvider);

    // Hide while loading or if daily cap reached
    final canWatch = capAsync.valueOrNull ?? false;
    if (!canWatch) return const SizedBox.shrink();

    final adService = ref.watch(rewardedAdServiceProvider);
    if (!adService.isReady) return const SizedBox.shrink();

    return GBtn(
      gradient: goldGrad,
      width: double.infinity,
      onPressed: () async {
        final earned = await ref.read(rewardedAdServiceProvider).show(
          onReward: () async {
            try {
              await grantAdEnergy();
            } catch (_) {
              // Energy grant failed — ad still watched, record cap to prevent re-show
            }
            await recordAdGrant();
          },
        );
        if (earned) {
          ref.invalidate(energyStateProvider);
          ref.invalidate(adEnergyCapProvider);
          onDismiss();
        }
      },
      child: Text(
        'Watch ad for +5⚡',
        style: GoogleFonts.nunito(
          color: textCol,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
