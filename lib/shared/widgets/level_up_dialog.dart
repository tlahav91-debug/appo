import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';

class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final String levelLabel;
  final int? xpCurrent;
  final int? xpForThisLevel;
  final int? xpForNextLevel;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.levelLabel,
    this.xpCurrent,
    this.xpForThisLevel,
    this.xpForNextLevel,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String levelLabel,
    int? xpCurrent,
    int? xpForThisLevel,
    int? xpForNextLevel,
  }) {
    return showDialog(
      context: context,
      barrierColor: bgDeep.withOpacity(0.92),
      barrierDismissible: true,
      builder: (_) => LevelUpDialog(
        newLevel: newLevel,
        levelLabel: levelLabel,
        xpCurrent: xpCurrent,
        xpForThisLevel: xpForThisLevel,
        xpForNextLevel: xpForNextLevel,
      ),
    );
  }

  double get _progressFraction {
    final cur = xpCurrent;
    final lo = xpForThisLevel;
    final hi = xpForNextLevel;
    if (cur == null || lo == null || hi == null || hi <= lo) return 0.0;
    return ((cur - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final showBar = xpCurrent != null && xpForNextLevel != null && xpForNextLevel! > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          Text(
            'Level Up!',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: goldGrad,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Level $newLevel · $levelLabel',
              style: GoogleFonts.sora(
                color: bgDeep,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressFraction,
                      backgroundColor: surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(gold),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpCurrent / $xpForNextLevel XP',
                    style: GoogleFonts.sora(color: textDim, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              decoration: BoxDecoration(
                gradient: cyanGrad,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.nunito(
                  color: bgDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
