import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart' show InAppPurchase, PurchaseParam;
import '../../../features/shop/application/iap_service.dart';
import '../../../features/shop/domain/gem_pack.dart';

class DramaPassService {
  final IAPService _iapService;

  DramaPassService(this._iapService) {
    _iapService.onPassPurchase = _onIAPResult;
  }

  Completer<PurchaseResult>? _pendingPurchase;

  void _onIAPResult(String productId, PurchaseResult result) {
    if (productId == 'drama_pass_monthly') {
      _pendingPurchase?.complete(result);
      _pendingPurchase = null;
    }
  }

  Future<bool> checkEntitlement() async => false;

  Future<String?> fetchLocalizedPrice() async =>
      _iapService.productForId('drama_pass_monthly')?.price;

  Future<PurchaseResult> subscribe() async {
    final product = _iapService.productForId('drama_pass_monthly');
    if (product == null) {
      return const PurchaseResult(
        status: PurchaseStatus.error,
        error: 'Product not available',
      );
    }
    final completer = Completer<PurchaseResult>();
    _pendingPurchase = completer;
    try {
      final param = PurchaseParam(productDetails: product);
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _pendingPurchase = null;
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
    return completer.future;
  }

  Future<PurchaseResult> restoreAndCheck() async {
    final completer = Completer<PurchaseResult>();
    _pendingPurchase = completer;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _pendingPurchase = null;
      return PurchaseResult(status: PurchaseStatus.error, error: e.toString());
    }
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingPurchase = null;
        return const PurchaseResult(
          status: PurchaseStatus.error,
          error: 'No active Drama Pass found.',
        );
      },
    );
  }
}
