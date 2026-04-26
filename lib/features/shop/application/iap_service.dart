import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kProductIds = {'gems_80', 'gems_500', 'gems_1500'};

class IAPService {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Cached products
  List<ProductDetails> products = [];

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen(_handlePurchases);

    final response = await _iap.queryProductDetails(_kProductIds);
    products = response.productDetails;
    // Sort: cheapest first
    products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  // Last validation error — callers may surface this to UI
  String? lastValidationError;

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _validate(p);
        await _iap.completePurchase(p);
      } else if (p.status == PurchaseStatus.error ||
                 p.status == PurchaseStatus.cancelled) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _validate(PurchaseDetails p) async {
    lastValidationError = null;
    try {
      final receiptData = Platform.isIOS
          ? p.verificationData.serverVerificationData
          : p.verificationData.localVerificationData;
      await Supabase.instance.client.functions.invoke(
        'validate-iap-receipt',
        body: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'product_id': p.productID,
          'receipt_data': receiptData,
          'transaction_id': p.purchaseID ?? p.productID,
        },
      );
    } catch (e) {
      lastValidationError = e.toString();
    }
  }

  Future<void> buy(String productId) async {
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> restore() async => _iap.restorePurchases();

  void dispose() => _sub?.cancel();
}
