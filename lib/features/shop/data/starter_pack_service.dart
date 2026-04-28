import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart' show InAppPurchase, PurchaseParam;
import 'package:shared_preferences/shared_preferences.dart';
import '../application/iap_service.dart';
import '../domain/gem_pack.dart';
import '../domain/starter_pack.dart';

const _kDismissedKey = 'starter_pack_dismissed';

class StarterPackService {
  final IAPService _iapService;

  StarterPackService(this._iapService) {
    _iapService.onNonGemPurchase = _onIAPResult;
  }

  Completer<PurchaseResult>? _pendingPurchase;

  void _onIAPResult(String productId, PurchaseResult result) {
    if (productId == 'drama_starter_pack') {
      _pendingPurchase?.complete(result);
      _pendingPurchase = null;
    }
  }

  Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDismissedKey) ?? false;
  }

  Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissedKey, true);
  }

  Future<StarterPackOffer?> fetchOffer() async {
    final price = _iapService.productForId('drama_starter_pack')?.price;
    return StarterPackOffer(localizedPrice: price);
  }

  Future<PurchaseResult> purchase() async {
    final product = _iapService.productForId('drama_starter_pack');
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
}
