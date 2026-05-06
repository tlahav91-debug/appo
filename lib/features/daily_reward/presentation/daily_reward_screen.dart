import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/profile/application/profile_provider.dart';
import '../../../features/profile/domain/fan_level.dart';
import '../../../shared/widgets/level_up_dialog.dart';
import '../application/daily_reward_provider.dart';

class DailyRewardScreen extends ConsumerStatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  ConsumerState<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends ConsumerState<DailyRewardScreen> {
  bool _claiming = false;

  static const _rewards = [
    {'coins': 10, 'gems': 0, 'xp': 0},
    {'coins': 15, 'gems': 0, 'xp': 0},
    {'coins': 20, 'gems': 0, 'xp': 0},
    {'coins': 25, 'gems': 0, 'xp': 0},
    {'coins': 0, 'gems': 1, 'xp': 0},
    {'coins': 30, 'gems': 0, 'xp': 0},
    {'coins': 0, 'gems': 2, 'xp': 50},
  ];

  _TileState _tileState(int day, int cycleDay, bool claimedToday) {
    if (day < cycleDay) return _TileState.claimed;
    if (day == cycleDay && claimedToday) return _TileState.claimed;
    if (day == cycleDay) return _TileState.active;
    return _TileState.locked;
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final res = await Supabase.instance.client.functions.invoke(
        'claim-daily-reward',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {},
      );
      final data = res.data as Map<String, dynamic>;
      final reward = data['reward'] as Map<String, dynamic>;
      final coins = (reward['coins'] as num?)?.toInt() ?? 0;
      final gems = (reward['gems'] as num?)?.toInt() ?? 0;
      final xp = (reward['xp'] as num?)?.toInt() ?? 0;
      final leveledUp = data['leveled_up'] as bool? ?? false;
      final newFanLevel = (data['new_fan_level'] as num?)?.toInt();
      final newXp = (data['new_xp'] as num?)?.toInt();
      ref.invalidate(dailyRewardProvider);
      ref.invalidate(profileProvider);
      if (mounted) {
        final parts = [
          if (coins > 0) '+$coins 🪙',
          if (gems > 0) '+$gems 💎',
          if (xp > 0) '+$xp XP',
        ];
        messenger.showSnackBar(SnackBar(content: Text(parts.join('  '))));
        setState(() => _claiming = false);
        if (leveledUp && newFanLevel != null && mounted) {
          final thresholds =
              ref.read(fanLevelThresholdsProvider).valueOrNull ?? <FanLevelThreshold>[];
          final match = thresholds.where((t) => t.level == newFanLevel);
          final label = match.isNotEmpty ? match.first.label : 'Lv.$newFanLevel';
          final nextMatch = thresholds.where((t) => t.level == newFanLevel + 1);
          await LevelUpDialog.show(
            context,
            newLevel: newFanLevel,
            levelLabel: label,
            xpCurrent: newXp,
            xpForThisLevel: match.isNotEmpty ? match.first.xpRequired : null,
            xpForNextLevel: nextMatch.isNotEmpty ? nextMatch.first.xpRequired : null,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Claim failed: $e')));
        setState(() => _claiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dailyRewardProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: const BackButton(color: textCol),
        title: Text(
          'Daily Reward',
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (_, __) => Center(
          child: Text('Could not load rewards', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (data) {
          final cycleDay = data['cycle_day'] as int;
          final claimedToday = data['claimed_today'] as bool;
          final streak = data['streak'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Streak chip
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak day streak',
                        style: GoogleFonts.nunito(
                          color: gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (streak >= 7) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: goldGrad,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 Streak ×2 bonus active!',
                        style: GoogleFonts.nunito(
                          color: bgDeep,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // 7-day grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, i) => _DayTile(
                    day: i + 1,
                    reward: _rewards[i],
                    state: _tileState(i + 1, cycleDay, claimedToday),
                    streakMultiplier: streak >= 7 ? 2 : 1,
                  ),
                ),
                const SizedBox(height: 28),
                // Claim button
                SizedBox(
                  height: 52,
                  child: _claiming
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: goldGrad,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: bgDeep, strokeWidth: 2),
                          ),
                        )
                      : claimedToday
                          ? Container(
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: borderHi),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '✓ Claimed today',
                                style: GoogleFonts.sora(color: textDim, fontSize: 13),
                              ),
                            )
                          : GestureDetector(
                              onTap: _claim,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: goldGrad,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Claim Day $cycleDay Reward',
                                  style: GoogleFonts.nunito(
                                    color: bgDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _TileState { claimed, active, locked }

class _DayTile extends StatelessWidget {
  final int day;
  final Map<String, Object> reward;
  final _TileState state;
  final int streakMultiplier;

  const _DayTile({
    required this.day,
    required this.reward,
    required this.state,
    required this.streakMultiplier,
  });

  String _rewardIcon() {
    if ((reward['gems'] as int) > 0) return '💎';
    if ((reward['xp'] as int) > 0) return '⭐';
    return '🪙';
  }

  String _rewardAmount() {
    final coins = (reward['coins'] as int) * streakMultiplier;
    final gems = reward['gems'] as int;
    final xp = reward['xp'] as int;
    if (gems > 0) return '×$gems';
    if (xp > 0) return '+$xp';
    return '+$coins';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: state == _TileState.active ? goldGrad : null,
            color: state == _TileState.active ? null : (state == _TileState.locked ? card : surface),
            borderRadius: BorderRadius.circular(12),
            border: state == _TileState.active
                ? null
                : Border.all(color: borderHi, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day $day',
                style: GoogleFonts.sora(
                  color: state == _TileState.active ? bgDeep : textDim,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(_rewardIcon(), style: const TextStyle(fontSize: 20)),
              Text(
                _rewardAmount(),
                style: GoogleFonts.nunito(
                  color: state == _TileState.active ? bgDeep : textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (state == _TileState.claimed)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bgDeep.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle, color: green, size: 22),
            ),
          ),
        if (state == _TileState.locked)
          Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.lock_outline, color: textDim, size: 14),
          ),
      ],
    );
  }
}
