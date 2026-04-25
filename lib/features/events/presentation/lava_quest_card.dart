import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/lava_quest.dart';

class LavaQuestCard extends StatelessWidget {
  final LavaQuest quest;

  const LavaQuestCard({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    final remaining = quest.timeRemaining;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final countdownLabel = h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';

    return GestureDetector(
      onTap: () => context.push('/quest/${quest.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: quest.isRewardClaimed ? null : lavaGrad,
          color: quest.isRewardClaimed ? card : null,
          borderRadius: BorderRadius.circular(16),
          border: quest.isRewardClaimed
              ? Border.all(color: border)
              : null,
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: quest.isRewardClaimed ? card : surface,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quest.title,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (quest.isRewardClaimed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: greenDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Collected',
                        style: GoogleFonts.sora(
                            color: green, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    )
                  else if (quest.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: lavaDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Claim!',
                        style: GoogleFonts.sora(
                            color: lava, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        '⏱ $countdownLabel',
                        style: GoogleFonts.sora(color: textDim, fontSize: 11),
                      ),
                    ),
                ],
              ),
              if (quest.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  quest.description!,
                  style: GoogleFonts.sora(color: textSec, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quest.progressFraction,
                  minHeight: 6,
                  backgroundColor: border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    quest.isCompleted ? green : lava,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quest.progress}/${quest.goalValue} episodes',
                    style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  ),
                  Row(
                    children: [
                      Text(
                        '💎 ${quest.rewardGems}',
                        style: GoogleFonts.nunito(
                          color: cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🪙 ${quest.rewardCoins}',
                        style: GoogleFonts.nunito(
                          color: gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
