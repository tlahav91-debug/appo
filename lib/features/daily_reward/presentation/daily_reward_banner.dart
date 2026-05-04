import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/daily_reward_provider.dart';

class DailyRewardBanner extends ConsumerWidget {
  const DailyRewardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailyRewardProvider);

    return dataAsync.when(
      loading: () => Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final cycleDay = data['cycle_day'] as int;
        final claimedToday = data['claimed_today'] as bool;
        final streak = data['streak'] as int;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Daily Reward',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      claimedToday
                          ? 'Come back tomorrow · $streak day streak'
                          : 'Day $cycleDay ready to claim!',
                      style: GoogleFonts.sora(color: textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!claimedToday)
                GestureDetector(
                  onTap: () => context.push('/daily-reward'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: goldGrad,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Claim',
                      style: GoogleFonts.nunito(
                        color: bgDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: green, size: 22),
            ],
          ),
        );
      },
    );
  }
}
