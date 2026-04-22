import 'package:purchases_flutter/purchases_flutter.dart';
import '../../shop/domain/gem_pack.dart';

const String _kProductId = 'drama_pass_monthly';
const String _kEntitlementId = 'drama_pass';

class DramaPassService {
  Future<bool> checkEntitlement() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_kEntitlementId);
    } catch (_) {
      return false;
    }
  }

  Future<String?> fetchLocalizedPrice() async {
    try {
      final offerings = await Purchases.getOfferings();
      for (final offering in offerings.all.values) {
        final pkg = offering.availablePackages
            .where((p) => p.storeProduct.identifier == _kProductId)
            .firstOrNull;
        if (pkg != null) return pkg.storeProduct.priceString;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseResult> subscribe() async {
    try {
      final offerings = await Purchases.getOfferings();
      Package? pkg;
      for (final offering in offerings.all.values) {
        pkg = offering.availablePackages
            .where((p) => p.storeProduct.identifier == _kProductId)
            .firstOrNull;
        if (pkg != null) break;
      }
      if (pkg == null) {
        return const PurchaseResult(
            status: PurchaseStatus.error, error: 'Drama Pass not available');
      }
      await Purchases.purchasePackage(pkg);
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

  Future<PurchaseResult> restoreAndCheck() async {
    try {
      await Purchases.restorePurchases();
      final active = await checkEntitlement();
      return PurchaseResult(
          status: active ? PurchaseStatus.success : PurchaseStatus.error,
          error: active ? null : 'No active Drama Pass found.');
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
  }
}
