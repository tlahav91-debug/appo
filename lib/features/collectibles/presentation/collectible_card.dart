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
    if (!owned) {
      return _UnownedCard();
    }
    return _OwnedCard(collectible: collectible);
  }

  static Color rarityColour(String rarity) => switch (rarity) {
        'legendary' => gold,
        'epic'      => purple,
        'rare'      => cyan,
        _           => borderHi, // common → grey
      };
}

// ---------------------------------------------------------------------------
// Owned card — image with rarity badge in bottom-right corner
// ---------------------------------------------------------------------------

class _OwnedCard extends StatelessWidget {
  final Collectible collectible;

  const _OwnedCard({required this.collectible});

  @override
  Widget build(BuildContext context) {
    final colour = CollectibleCard.rarityColour(collectible.rarity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or purple-gradient fallback
          collectible.imageUrl != null
              ? Image.network(
                  collectible.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _PurpleGradientPlaceholder(),
                )
              : const _PurpleGradientPlaceholder(),
          // Subtle scrim at bottom so badge is legible
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
          // Rarity badge — bottom-right
          Positioned(
            right: 6,
            bottom: 6,
            child: _RarityBadge(rarity: collectible.rarity, colour: colour),
          ),
        ],
      ),
    );
  }
}

class _PurpleGradientPlaceholder extends StatelessWidget {
  const _PurpleGradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: purpleGrad),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final String rarity;
  final Color colour;

  const _RarityBadge({required this.rarity, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.toUpperCase(),
        style: GoogleFonts.sora(
          color: bgDeep,
          fontWeight: FontWeight.w700,
          fontSize: 8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unowned card — dark surface with centred '?' in textSec colour
// ---------------------------------------------------------------------------

class _UnownedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          '?',
          style: GoogleFonts.nunito(
            color: textSec,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}
