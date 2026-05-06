import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/profile_provider.dart';
import '../domain/fan_level.dart';

// Milestone perks displayed at specific levels
const _kLevelPerks = <int, String>{
  5:  '🎖️ Bronze Fan title',
  10: '⚡ +1 energy cap (21 max)',
  15: '🥈 Silver Fan title',
  20: '💫 Gold profile border',
  25: '🎭 Veteran Fan title',
  30: '🏆 Legend border + double streak XP',
};

class LevelPerksScreen extends ConsumerWidget {
  const LevelPerksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final thresholdsAsync = ref.watch(fanLevelThresholdsProvider);

    final profile = profileAsync.valueOrNull;
    final thresholds = thresholdsAsync.valueOrNull ?? <FanLevelThreshold>[];
    final currentLevel = profile?.fanLevel ?? 1;
    final currentXp = profile?.xp ?? 0;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: const BackButton(color: textCol),
        title: Text(
          'Fan Levels',
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: thresholds.isEmpty
          ? const Center(child: CircularProgressIndicator(color: gold))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: thresholds.length,
              itemBuilder: (context, i) {
                final t = thresholds[i];
                final next = i + 1 < thresholds.length ? thresholds[i + 1] : null;
                final isCurrent = t.level == currentLevel;
                final isUnlocked = t.level <= currentLevel;
                final perk = _kLevelPerks[t.level];

                // XP progress within this level (only for current level)
                final progressFraction = isCurrent && next != null
                    ? ((currentXp - t.xpRequired) / (next.xpRequired - t.xpRequired))
                        .clamp(0.0, 1.0)
                    : isUnlocked
                        ? 1.0
                        : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent ? surface : card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? gold : (isUnlocked ? borderHi : border),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isUnlocked ? goldGrad : null,
                              color: isUnlocked ? null : surface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${t.level}',
                              style: GoogleFonts.nunito(
                                color: isUnlocked ? bgDeep : textDim,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.label,
                                      style: GoogleFonts.nunito(
                                        color: isUnlocked ? textCol : textDim,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: pinkFull,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'YOU ARE HERE',
                                          style: GoogleFonts.sora(
                                            color: textCol,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  next != null
                                      ? '${t.xpRequired} XP'
                                      : '${t.xpRequired} XP · Max Level',
                                  style: GoogleFonts.sora(
                                    color: textDim,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isUnlocked && next != null)
                            Text(
                              '${t.xpRequired - currentXp} XP away',
                              style: GoogleFonts.sora(color: textDim, fontSize: 10),
                            ),
                        ],
                      ),
                      if (isCurrent && next != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor: border,
                            valueColor: const AlwaysStoppedAnimation<Color>(gold),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentXp / ${next.xpRequired} XP · ${next.xpRequired - currentXp} to next',
                          style: GoogleFonts.sora(color: textDim, fontSize: 10),
                        ),
                      ],
                      if (perk != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? gold.withOpacity(0.12)
                                : surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            perk,
                            style: GoogleFonts.sora(
                              color: isUnlocked ? gold : textDim,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
