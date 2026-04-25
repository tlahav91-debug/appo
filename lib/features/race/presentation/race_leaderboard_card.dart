import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/race_participant.dart';

class RaceLeaderboardCard extends StatelessWidget {
  final RaceParticipant participant;
  final int position;
  final bool isMe;

  const RaceLeaderboardCard({
    super.key,
    required this.participant,
    required this.position,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final rankLabel = _rankLabel(position);
    final isTop3 = position <= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? purpleDim : card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? purple : (isTop3 ? _rankColor(position) : border),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: isTop3
                ? Text(
                    rankLabel,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '#$position',
                    style: GoogleFonts.nunito(
                      color: textDim,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: purpleDim,
            backgroundImage: participant.avatarUrl != null
                ? NetworkImage(participant.avatarUrl!)
                : null,
            child: participant.avatarUrl == null
                ? Text(
                    participant.displayName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.displayName,
              style: GoogleFonts.nunito(
                color: isMe ? textCol : textSec,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${participant.episodesWatched}',
                style: GoogleFonts.nunito(
                  color: isTop3 ? _rankColor(position) : (isMe ? purple : textSec),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                'episodes',
                style: GoogleFonts.sora(color: textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _rankLabel(int pos) {
    switch (pos) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$pos';
    }
  }

  Color _rankColor(int pos) {
    switch (pos) {
      case 1: return gold;
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return textSec;
    }
  }
}
