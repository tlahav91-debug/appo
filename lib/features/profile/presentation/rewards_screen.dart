import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';
import '../../../features/profile/application/profile_provider.dart';
import '../../../features/rewards/application/streak_provider.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _claiming = false;

  Future<void> _claimStreak() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    final result = await ref.read(streakServiceProvider).claimDaily();

    if (!mounted) return;
    setState(() => _claiming = false);

    if (result.claimed) {
      ref.invalidate(streakStatusProvider);
      ref.invalidate(profileProvider);
      final parts = <String>[];
      if (result.coinsEarned > 0) parts.add('🪙 ${result.coinsEarned}');
      if (result.gemsEarned > 0) parts.add('💎 ${result.gemsEarned}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Day ${result.streakDay} claimed! ${parts.join('  ')}',
            style: GoogleFonts.nunito(color: textCol)),
        backgroundColor: card,
        duration: const Duration(seconds: 3),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Claim failed', style: GoogleFonts.nunito(color: textCol)),
        backgroundColor: lava,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(streakStatusProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              // Rankings button
              GestureDetector(
                onTap: () => context.push('/leaderboard'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(gradient: pinkFull, borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Rankings', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // Daily Streak header
              Text('Daily Streak', style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 4),
              Text('Check in every day for escalating rewards', style: GoogleFonts.sora(color: textSec, fontSize: 13)),
              const SizedBox(height: 16),

              // Streak card
              streakAsync.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: pink, strokeWidth: 2))),
                error: (_, __) => Center(child: Text('Failed to load', style: GoogleFonts.sora(color: textDim))),
                data: (status) => _StreakCard(status: status, claiming: _claiming, onClaim: _claimStreak),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakStatus status;
  final bool claiming;
  final VoidCallback onClaim;

  const _StreakCard({required this.status, required this.claiming, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderHi),
      ),
      child: Column(
        children: [
          // Streak count
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(
              '${status.currentStreak} Day Streak',
              style: GoogleFonts.nunito(color: gold, fontWeight: FontWeight.w900, fontSize: 26),
            ),
          ]),
          const SizedBox(height: 20),

          // 7-day calendar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isDone = i < status.currentStreak;
              final isToday = dayNum == status.currentStreak + (status.claimedToday ? 0 : 1);
              final reward = streakRewards[i];
              return _DayTile(
                day: dayNum,
                isDone: isDone,
                isToday: isToday && !status.claimedToday,
                coins: reward.coins,
                gems: reward.gems,
              );
            }),
          ),
          const SizedBox(height: 24),

          // Claim button
          if (status.claimedToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14)),
              child: Text(
                '✓ Claimed today — come back tomorrow!',
                style: GoogleFonts.nunito(color: textDim, fontWeight: FontWeight.w700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          else
            GestureDetector(
              onTap: claiming ? null : onClaim,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: pinkFull, borderRadius: BorderRadius.circular(14)),
                child: claiming
                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : Text(
                        'Claim Day ${(status.currentStreak % 7) + 1} Reward',
                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),

          const SizedBox(height: 12),
          Text(
            'Drama Pass holders get 2× rewards',
            style: GoogleFonts.sora(color: textDim, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final bool isDone;
  final bool isToday;
  final int coins;
  final int gems;

  const _DayTile({required this.day, required this.isDone, required this.isToday, required this.coins, required this.gems});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDone ? goldGrad : isToday ? pinkGrad : null,
            color: isDone || isToday ? null : surface,
            border: isToday ? Border.all(color: pink, width: 2) : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text('$day', style: GoogleFonts.nunito(color: isToday ? Colors.white : textDim, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 4),
        Text('🪙$coins', style: GoogleFonts.sora(color: textDim, fontSize: 9)),
        if (gems > 0) Text('💎$gems', style: GoogleFonts.sora(color: cyan, fontSize: 9)),
      ],
    );
  }
}
