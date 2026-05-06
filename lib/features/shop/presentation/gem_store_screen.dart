import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/iap_provider.dart';

// Pack metadata
class _Pack {
  final String productId;
  final String label;
  final String title;
  final LinearGradient gradient;

  const _Pack(this.productId, this.label, this.title, this.gradient);
}

const _packs = [
  _Pack('drama_gems_100',  '100 💎',  'Starter Pack', cyanGrad),
  _Pack('drama_gems_500',  '500 💎',  'Popular Pack', pinkFull),
  _Pack('drama_gems_1500', '1500 💎', 'Best Value',   goldGrad),
];

class GemStoreScreen extends ConsumerWidget {
  const GemStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iapService = ref.watch(iapServiceProvider);
    final products = iapService.products;
    final isLoading = products.isEmpty;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: cyan))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Text(
                      'Gem Store 💎',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final pack = _packs[i];
                      // Find matching product for price string
                      final product = products.where((p) => p.id == pack.productId).firstOrNull;
                      return _GemPackCard(
                        pack: pack,
                        priceString: product?.price ?? '—',
                        onTap: () async {
                          try {
                            await iapService.buy(pack.productId);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst('Exception: ', ''),
                                    style: GoogleFonts.sora(color: textCol),
                                  ),
                                  backgroundColor: surface,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                    childCount: _packs.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    child: Center(
                      child: TextButton(
                        onPressed: () => iapService.restore(),
                        child: Text(
                          'Restore Purchases',
                          style: GoogleFonts.sora(color: textDim, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GemPackCard extends StatelessWidget {
  final _Pack pack;
  final String priceString;
  final VoidCallback onTap;

  const _GemPackCard({
    required this.pack,
    required this.priceString,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderHi, width: 1.5),
        ),
        child: Stack(
          children: [
            // Gradient border accent (left edge)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: pack.gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  // Gem amount label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.label,
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pack.title,
                          style: GoogleFonts.sora(
                            color: textSec,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price button with gradient border
                  _GradientBorderButton(
                    gradient: pack.gradient,
                    onTap: onTap,
                    child: Text(
                      priceString,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBorderButton extends StatelessWidget {
  final LinearGradient gradient;
  final VoidCallback onTap;
  final Widget child;

  const _GradientBorderButton({
    required this.gradient,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(11),
          ),
          child: child,
        ),
      ),
    );
  }
}
