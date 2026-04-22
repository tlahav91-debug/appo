import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/gem_pack.dart';
import '../domain/starter_pack.dart';

const _kDismissedKey = 'starter_pack_dismissed';

class StarterPackService {
  Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDismissedKey) ?? false;
  }

  Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissedKey, true);
  }

  Future<StarterPackOffer?> fetchOffer() async {
    try {
      final offerings = await Purchases.getOfferings();
      for (final offering in offerings.all.values) {
        final pkg = offering.availablePackages
            .where((p) => p.storeProduct.identifier == StarterPackOffer.productId)
            .firstOrNull;
        if (pkg != null) {
          return StarterPackOffer(localizedPrice: pkg.storeProduct.priceString);
        }
      }
      return const StarterPackOffer(localizedPrice: '\$2.99');
    } catch (_) {
      return const StarterPackOffer(localizedPrice: '\$2.99');
    }
  }

  Future<PurchaseResult> purchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      Package? pkg;
      for (final offering in offerings.all.values) {
        pkg = offering.availablePackages
            .where((p) => p.storeProduct.identifier == StarterPackOffer.productId)
            .firstOrNull;
        if (pkg != null) break;
      }
      if (pkg == null) {
        return const PurchaseResult(
            status: PurchaseStatus.error, error: 'Starter Pack not available');
      }
      await Purchases.purchasePackage(pkg);
      await markDismissed();
      return const PurchaseResult(status: PurchaseStatus.success);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(status: PurchaseStatus.cancelled);
      }
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
  }
}
