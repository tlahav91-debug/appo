import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/character_affinity.dart';

class AffinityCard extends StatelessWidget {
  final CharacterAffinity affinity;

  const AffinityCard({super.key, required this.affinity});

  @override
  Widget build(BuildContext context) {
    final char = affinity.character;
    final level = affinity.level;
    final borderColor = _levelColor(level);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with level border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [borderColor.withAlpha(180), borderColor.withAlpha(60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: surface,
              backgroundImage:
                  char.avatarUrl != null ? NetworkImage(char.avatarUrl!) : null,
              child: char.avatarUrl == null
                  ? Text(
                      char.name.isNotEmpty
                          ? char.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            char.name,
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${affinity.levelEmoji} ${affinity.levelLabel}',
              style: GoogleFonts.sora(
                color: borderColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: affinity.levelFraction,
              minHeight: 5,
              backgroundColor: border,
              valueColor: AlwaysStoppedAnimation<Color>(borderColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            level < 3
                ? '${affinity.pointsToNextLevel} pts to next'
                : 'Max level',
            style: GoogleFonts.sora(color: textDim, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _levelColor(int level) {
    switch (level) {
      case 3: return pink;
      case 2: return purple;
      default: return cyan;
    }
  }
}
