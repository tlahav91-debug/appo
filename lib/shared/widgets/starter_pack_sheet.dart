import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/shop/application/starter_pack_provider.dart';
import '../../features/shop/domain/gem_pack.dart';
import '../../features/shop/domain/starter_pack.dart';

class StarterPackSheet extends ConsumerStatefulWidget {
  final StarterPackOffer offer;

  const StarterPackSheet({super.key, required this.offer});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final service = ref.read(starterPackServiceProvider);
    final offer = await ref.read(starterPackOfferProvider.future);
    if (offer == null) return;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StarterPackSheet(offer: offer),
    );
  }

  @override
  ConsumerState<StarterPackSheet> createState() => _StarterPackSheetState();
}

class _StarterPackSheetState extends ConsumerState<StarterPackSheet> {
  Future<void> _dismiss() async {
    await ref.read(starterPackServiceProvider).markDismissed();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseAsync = ref.watch(starterPackPurchaseNotifierProvider);
    final isLoading = purchaseAsync.isLoading;

    ref.listen(starterPackPurchaseNotifierProvider, (_, next) {
      if (!next.hasValue || next.value == null) return;
      final result = next.value!;
      if (result.status == PurchaseStatus.success) {
        ref.invalidate(profileProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Starter Pack unlocked! 🎉',
              style: GoogleFonts.sora(color: textCol)),
          backgroundColor: green,
        ));
      } else if (result.status == PurchaseStatus.error && result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error!, style: GoogleFonts.sora(color: textCol)),
          backgroundColor: surface,
        ));
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderHi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🎁', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            'Welcome Offer',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One-time offer for new players',
            style: GoogleFonts.sora(color: textDim, fontSize: 12),
          ),
          const SizedBox(height: 24),
          // Bundle contents
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BundleItem(emoji: '💎', amount: '${StarterPackOffer.gems}', color: cyan),
              const SizedBox(width: 32),
              _BundleItem(emoji: '🪙', amount: '${StarterPackOffer.coins}', color: gold),
            ],
          ),
          const SizedBox(height: 28),
          // Buy button
          GestureDetector(
            onTap: isLoading
                ? null
                : () => ref.read(starterPackPurchaseNotifierProvider.notifier).buy(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: pinkFull,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
                      )
                    : Text(
                        'Get it now · ${widget.offer.localizedPrice ?? '\$2.99'}',
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : _dismiss,
            child: Text(
              'No thanks',
              style: GoogleFonts.sora(color: textDim, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleItem extends StatelessWidget {
  final String emoji;
  final String amount;
  final Color color;

  const _BundleItem({
    required this.emoji,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.nunito(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
