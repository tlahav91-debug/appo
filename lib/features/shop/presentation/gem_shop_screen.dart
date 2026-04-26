import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/gem_shop_provider.dart';
import '../domain/gem_pack.dart';
import 'gem_pack_card.dart';

class GemShopScreen extends ConsumerWidget {
  const GemShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(gemPacksProvider);
    final purchaseAsync = ref.watch(purchaseNotifierProvider);
    final loadingProductId = _loadingId(purchaseAsync);

    ref.listen(purchaseNotifierProvider, (_, next) {
      if (!next.hasValue) return;
      final result = next.value;
      if (result == null) return;
      if (result.status == PurchaseStatus.success && result.productId != null) {
        ref.read(analyticsProvider).capture('gem_pack_purchased', properties: {
          'product_id': result.productId,
        });
      }
      final msg = switch (result.status) {
        PurchaseStatus.success   => 'Purchase complete! Gems will appear shortly.',
        PurchaseStatus.cancelled => null,
        PurchaseStatus.error     => result.error ?? 'Purchase failed.',
        _                        => null,
      };
      if (msg != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.sora(color: textCol)),
          backgroundColor: result.status == PurchaseStatus.success ? green : surface,
        ));
      }
    });

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: packsAsync.when(
        data: (packs) => _ShopBody(
          packs: packs,
          loadingProductId: loadingProductId,
          onBuy: (productId) =>
              ref.read(purchaseNotifierProvider.notifier).buy(productId),
          onRestore: () =>
              ref.read(purchaseNotifierProvider.notifier).restore(),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: pink)),
        error: (_, __) => Center(
          child: Text('Shop unavailable', style: GoogleFonts.sora(color: textSec)),
        ),
      ),
    );
  }

  String? _loadingId(AsyncValue<PurchaseResult?> state) {
    return state.isLoading ? '' : null;
  }
}

class _ShopBody extends StatelessWidget {
  final List<GemPack> packs;
  final String? loadingProductId;
  final void Function(String) onBuy;
  final VoidCallback onRestore;

  const _ShopBody({
    required this.packs,
    required this.loadingProductId,
    required this.onBuy,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              children: [
                const Text('💎', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'Get Gems',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use gems to refill energy and unlock premium content.',
                  style: GoogleFonts.sora(color: textSec, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => GemPackCard(
              pack: packs[i],
              isLoading: loadingProductId != null,
              onBuy: () => onBuy(packs[i].productId),
            ),
            childCount: packs.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            child: Center(
              child: TextButton(
                onPressed: loadingProductId != null ? null : onRestore,
                child: Text(
                  'Restore Purchases',
                  style: GoogleFonts.sora(color: textDim, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
