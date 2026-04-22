import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/collectible.dart';

class CollectibleCard extends StatelessWidget {
  final Collectible collectible;
  final bool owned;

  const CollectibleCard({
    super.key,
    required this.collectible,
    required this.owned,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: owned ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: owned ? _rarityColour(collectible.rarity) : border,
            width: owned ? 1.5 : 1,
          ),
          boxShadow: owned
              ? [
                  BoxShadow(
                    color: _rarityColour(collectible.rarity).withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: collectible.imageUrl != null
                    ? ColorFiltered(
                        colorFilter: owned
                            ? const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]),
                        child: Image.network(
                          collectible.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        color: cardHi,
                        child: Icon(
                          owned ? Icons.auto_awesome : Icons.lock_outline,
                          color: owned
                              ? _rarityColour(collectible.rarity)
                              : textDim,
                          size: 28,
                        ),
                      ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collectible.name,
                    style: GoogleFonts.nunito(
                      color: owned ? textCol : textDim,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _RarityChip(rarity: collectible.rarity, owned: owned),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _rarityColour(String rarity) => switch (rarity) {
        'legendary' => gold,
        'epic'      => purple,
        'rare'      => cyan,
        _           => borderHi,
      };
}

class _RarityChip extends StatelessWidget {
  final String rarity;
  final bool owned;

  const _RarityChip({required this.rarity, required this.owned});

  @override
  Widget build(BuildContext context) {
    final colour = CollectibleCard._rarityColour(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: owned ? colour.withOpacity(0.2) : surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.toUpperCase(),
        style: GoogleFonts.sora(
          color: owned ? colour : textDim,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
