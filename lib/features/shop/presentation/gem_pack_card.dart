import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../domain/gem_pack.dart';

class GemPackCard extends StatelessWidget {
  final GemPack pack;
  final bool isLoading;
  final VoidCallback onBuy;

  const GemPackCard({
    super.key,
    required this.pack,
    required this.isLoading,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final isFeatured = pack.badge != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: isFeatured ? purpleGrad : null,
        color: isFeatured ? null : card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? purple : borderHi,
          width: isFeatured ? 0 : 1,
        ),
        boxShadow: isFeatured
            ? [BoxShadow(color: purple.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            // Gem icon + amount
            Column(
              children: [
                const Text('💎', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 2),
                Text(
                  _fmtGems(pack.gemsAmount),
                  style: GoogleFonts.nunito(
                    color: cyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Title + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.title,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  if (pack.badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pack.badge!,
                        style: GoogleFonts.nunito(
                          color: gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Buy button
            GestureDetector(
              onTap: isLoading ? null : onBuy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: goldGrad,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: bgDeep),
                      )
                    : Text(
                        pack.localizedPrice,
                        style: GoogleFonts.nunito(
                          color: bgDeep,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtGems(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';
}
