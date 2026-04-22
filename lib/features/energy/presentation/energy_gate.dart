import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/g_btn.dart';
import '../../../shared/widgets/energy_timer.dart';
import '../application/energy_provider.dart';
import '../data/watch_episode_service.dart';

class EnergyGate extends ConsumerStatefulWidget {
  final int currentEnergy;

  const EnergyGate({super.key, required this.currentEnergy});

  static Future<void> show(BuildContext context, {required int currentEnergy}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnergyGate(currentEnergy: currentEnergy),
    );
  }

  @override
  ConsumerState<EnergyGate> createState() => _EnergyGateState();
}

class _EnergyGateState extends ConsumerState<EnergyGate> {
  bool _adLoading = false;
  bool _gemLoading = false;
  String? _feedback;

  Future<void> _claimAdReward() async {
    setState(() { _adLoading = true; _feedback = null; });
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
          : 'Ad unavailable. Try again later.');
    }
    if (mounted) setState(() => _adLoading = false);
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

    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: borderHi, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          const Text('⚡', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('Not Enough Energy',
              style: GoogleFonts.nunito(color: gold, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 6),
          Text('${energy.current} / ${EnergyState.max} ⚡',
              style: GoogleFonts.sora(color: textSec, fontSize: 14)),
          const SizedBox(height: 4),
          const EnergyTimer(),
          const SizedBox(height: 24),

          // Option 1 — Rewarded ad
          GBtn(
            gradient: greenGrad,
            width: double.infinity,
            onPressed: _adLoading ? null : _claimAdReward,
            child: _adLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textCol))
                : Text('Watch an Ad · Get 2 ⚡ free',
                    style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(height: 10),

          // Option 2 — Gem refill
          GBtn(
            gradient: purpleGrad,
            width: double.infinity,
            onPressed: _gemLoading ? null : _claimGemRefill,
            child: _gemLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textCol))
                : Text('Refill to Full · 50 💎',
                    style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(height: 10),

          // Option 3 — Buy gems
          GBtn(
            gradient: goldGrad,
            width: double.infinity,
            onPressed: () {
              Navigator.pop(context);
              context.push('/shop/gems');
            },
            child: Text('Get Gems',
                style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(height: 10),

          // Option 4 — Wait
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Wait for free energy',
                style: GoogleFonts.sora(color: textDim, fontSize: 14)),
          ),

          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Text(_feedback!, style: GoogleFonts.sora(color: pink, fontSize: 12), textAlign: TextAlign.center),
          ],

          const SizedBox(height: 8),
          Text('Drama Pass members get +5 energy daily',
              style: GoogleFonts.sora(color: textDim, fontSize: 11)),
        ],
      ),
    );
  }
}
