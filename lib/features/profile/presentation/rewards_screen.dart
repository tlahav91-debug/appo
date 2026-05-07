import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

              // Streak card + optional break banner
              streakAsync.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: pink, strokeWidth: 2))),
                error: (_, __) => Center(child: Text('Failed to load', style: GoogleFonts.sora(color: textDim))),
                data: (status) => Column(
                  children: [
                    if (status.streakBroken)
                      _StreakBreakBanner(shieldAvailable: status.shieldAvailable),
                    _StreakCard(status: status, claiming: _claiming, onClaim: _claimStreak),
                  ],
                ),
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
              // Highlight today's unclaimed slot (BUG-027-H-2 fix)
              final isActiveToday = !status.claimedToday && dayNum == status.currentStreak + 1;
              final reward = streakRewards[i];
              return _DayTile(
                day: dayNum,
                isDone: isDone,
                isToday: isActiveToday,
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

// ---------------------------------------------------------------------------
// Streak Break Banner
// ---------------------------------------------------------------------------

class _StreakBreakBanner extends ConsumerStatefulWidget {
  final bool shieldAvailable;

  const _StreakBreakBanner({required this.shieldAvailable});

  @override
  ConsumerState<_StreakBreakBanner> createState() => _StreakBreakBannerState();
}

class _StreakBreakBannerState extends ConsumerState<_StreakBreakBanner> {
  bool _loading = false;
  String? _error;

  Future<void> _useShield(String type) async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final res = await Supabase.instance.client.functions.invoke(
        'use-streak-shield',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'type': type},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['restored'] == true) {
        ref.invalidate(streakStatusProvider);
        ref.invalidate(profileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔥 Streak restored!',
                style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
              ),
              backgroundColor: surface,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on FunctionException catch (fe) {
      final body = fe.details;
      String msg = 'Something went wrong';
      if (fe.status == 402) {
        msg = body is Map && body['error'] == 'Insufficient gems'
            ? 'Not enough 💎 gems'
            : 'Shield not available';
      }
      if (mounted) setState(() { _error = msg; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Something went wrong'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderHi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '😔 Streak broken',
            style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Use a shield to restore your streak',
            style: GoogleFonts.sora(color: textSec, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.sora(color: pink, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (widget.shieldAvailable) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _loading ? null : () => _useShield('free'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: purpleGrad,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: textCol))
                            : Text('🛡️ Free Shield', style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: _loading ? null : () => _useShield('paid'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: goldGrad,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: bgDeep))
                          : Text('💎 50 gems', style: GoogleFonts.nunito(color: bgDeep, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
