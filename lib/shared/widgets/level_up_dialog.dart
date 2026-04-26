import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';

class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final String levelLabel;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.levelLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String levelLabel,
  }) {
    return showDialog(
      context: context,
      barrierColor: bgDeep.withOpacity(0.92),
      barrierDismissible: true,
      builder: (_) => LevelUpDialog(newLevel: newLevel, levelLabel: levelLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
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
