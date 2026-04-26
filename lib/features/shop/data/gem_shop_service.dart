import 'package:purchases_flutter/purchases_flutter.dart';
import '../domain/gem_pack.dart';

const Map<String, int> _gemAmounts = {
  'drama_gems_100':  100,
  'drama_gems_500':  500,
  'drama_gems_1200': 1200,
  'drama_gems_3000': 3000,
};

const Map<String, String> _badges = {
  'drama_gems_500':  'POPULAR',
  'drama_gems_1200': 'BEST VALUE',
};

const Map<String, String> _titles = {
  'drama_gems_100':  'Starter Pack',
  'drama_gems_500':  'Drama Pack',
  'drama_gems_1200': 'Power Pack',
  'drama_gems_3000': 'Ultimate Pack',
};

class GemShopService {
  // Retained to execute purchases without re-fetching
  List<Package> _cachedPackages = [];

  Future<List<GemPack>> fetchPacks() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return _fallbackPacks();
      _cachedPackages = current.availablePackages;
      final packs = _cachedPackages
          .map(_toGemPack)
          .whereType<GemPack>()
          .toList();
      return packs.isEmpty ? _fallbackPacks() : packs;
    } catch (_) {
      return _fallbackPacks();
    }
  }

  Future<PurchaseResult> purchase(String productId) async {
    try {
      final pkg = _cachedPackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
        orElse: () => throw Exception('Package $productId not found in cache'),
      );
      await Purchases.purchasePackage(pkg);
      return PurchaseResult(status: PurchaseStatus.success, productId: productId);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(status: PurchaseStatus.cancelled);
      }
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      return const PurchaseResult(status: PurchaseStatus.success);
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
  }

  GemPack? _toGemPack(Package pkg) {
    final productId = pkg.storeProduct.identifier;
    final gems = _gemAmounts[productId];
    if (gems == null) return null;
    return GemPack(
      productId: productId,
      gemsAmount: gems,
      title: _titles[productId] ?? productId,
      localizedPrice: pkg.storeProduct.priceString,
      badge: _badges[productId],
    );
  }

  // Shown when RevenueCat is unavailable (no prices — dev/offline mode)
  List<GemPack> _fallbackPacks() => [
        const GemPack(productId: 'drama_gems_100',  gemsAmount: 100,  title: 'Starter Pack',  localizedPrice: '\$0.99'),
        const GemPack(productId: 'drama_gems_500',  gemsAmount: 500,  title: 'Drama Pack',    localizedPrice: '\$3.99',  badge: 'POPULAR'),
        const GemPack(productId: 'drama_gems_1200', gemsAmount: 1200, title: 'Power Pack',    localizedPrice: '\$7.99',  badge: 'BEST VALUE'),
        const GemPack(productId: 'drama_gems_3000', gemsAmount: 3000, title: 'Ultimate Pack', localizedPrice: '\$14.99'),
      ];
}
