import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/episode.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final bool isUnlocked;
  final bool isCompleted;
  final int progressPct;
  final VoidCallback onTap;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.isUnlocked,
    this.isCompleted = false,
    this.progressPct = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accessible = episode.isFree || isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accessible ? borderHi : border,
            width: accessible ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
              child: Stack(
                children: [
                  SizedBox(
                    width: 88,
                    height: 72,
                    child: episode.thumbnailUrl != null
                        ? Image.network(episode.thumbnailUrl!, fit: BoxFit.cover)
                        : Container(
                            color: cardHi,
                            child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
                          ),
                  ),
                  // Progress bar at bottom of thumbnail
                  if (progressPct > 0 && !isCompleted)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: LinearProgressIndicator(
                        value: progressPct / 100.0,
                        minHeight: 3,
                        backgroundColor: Colors.black45,
                        valueColor: AlwaysStoppedAnimation<Color>(pink),
                      ),
                    ),
                  // Completed overlay checkmark
                  if (isCompleted)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EP ${episode.episodeNumber}',
                    style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.title,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _badge(accessible),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool accessible) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: greenGrad,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Watched',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      );
    }
    if (accessible) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: episode.isFree ? greenGrad : cyanGrad,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          episode.isFree ? 'FREE' : '✓',
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: textDim, size: 12),
          const SizedBox(width: 3),
          if (episode.coinCost > 0) ...[
            Text(
              '${episode.coinCost}🪙',
              style: GoogleFonts.nunito(
                color: gold,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            Text(
              ' · ${episode.energyCost}⚡',
              style: GoogleFonts.nunito(
                color: textSec,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ] else
            Text(
              '${episode.energyCost}⚡',
              style: GoogleFonts.nunito(
                color: textSec,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
