import '../domain/gem_pack.dart';

class GemShopService {
  Future<List<GemPack>> fetchPacks() async => _fallbackPacks();

  Future<PurchaseResult> purchase(String productId) async =>
      const PurchaseResult(
          status: PurchaseStatus.error,
          error: 'Use the Gem Store for purchases.');

  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult(
          status: PurchaseStatus.error,
          error: 'Use the Gem Store for purchases.');

  List<GemPack> _fallbackPacks() => [
        const GemPack(productId: 'gems_80',   gemsAmount: 80,   title: 'Starter Pack', localizedPrice: '\$0.99'),
        const GemPack(productId: 'gems_500',  gemsAmount: 500,  title: 'Popular Pack',  localizedPrice: '\$4.99', badge: 'POPULAR'),
        const GemPack(productId: 'gems_1500', gemsAmount: 1500, title: 'Best Value',    localizedPrice: '\$9.99', badge: 'BEST VALUE'),
      ];
}
