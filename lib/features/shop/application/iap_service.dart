import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gem_pack.dart' as domain;

const _kProductIds = {'gems_80', 'gems_500', 'gems_1500', 'drama_starter_pack', 'drama_pass_monthly'};

class IAPService {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Cached products
  List<ProductDetails> products = [];

  // Called when a non-gem IAP (starter pack) resolves
  void Function(String productId, domain.PurchaseResult result)? onNonGemPurchase;

  // Called when drama_pass_monthly purchase or restore resolves
  void Function(String productId, domain.PurchaseResult result)? onPassPurchase;

  // Last validation error — callers may surface this to UI
  String? lastValidationError;

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen(_handlePurchases);

    final response = await _iap.queryProductDetails(_kProductIds);
    products = response.productDetails;
    // Sort: cheapest first
    products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  ProductDetails? productForId(String id) =>
      products.where((p) => p.id == id).firstOrNull;

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == 'drama_starter_pack') {
          await _grantStarterPack(p);
        } else if (p.productID == 'drama_pass_monthly') {
          await _activateDramaPass(p);
        } else {
          await _validate(p);
        }
        await _iap.completePurchase(p);
      } else if (p.status == PurchaseStatus.error ||
                 p.status == PurchaseStatus.cancelled) {
        if (p.productID == 'drama_pass_monthly') {
          onPassPurchase?.call(
            p.productID,
            domain.PurchaseResult(
              status: p.status == PurchaseStatus.cancelled
                  ? domain.PurchaseStatus.cancelled
                  : domain.PurchaseStatus.error,
              error: p.error?.message,
              productId: p.productID,
            ),
          );
        } else if (p.productID == 'drama_starter_pack') {
          onNonGemPurchase?.call(
            p.productID,
            domain.PurchaseResult(
              status: p.status == PurchaseStatus.cancelled
                  ? domain.PurchaseStatus.cancelled
                  : domain.PurchaseStatus.error,
              error: p.error?.message,
              productId: p.productID,
            ),
          );
        }
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

  Future<void> _grantStarterPack(PurchaseDetails p) async {
    try {
      final receiptData = Platform.isIOS
          ? p.verificationData.serverVerificationData
          : p.verificationData.localVerificationData;
      await Supabase.instance.client.functions.invoke(
        'grant-starter-pack',
        body: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'receipt_data': receiptData,
          'transaction_id': p.purchaseID ?? p.productID,
        },
      );
      onNonGemPurchase?.call(
        p.productID,
        const domain.PurchaseResult(status: domain.PurchaseStatus.success),
      );
    } catch (e) {
      onNonGemPurchase?.call(
        p.productID,
        domain.PurchaseResult(
          status: domain.PurchaseStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _activateDramaPass(PurchaseDetails p) async {
    try {
      final receiptData = Platform.isIOS
          ? p.verificationData.serverVerificationData
          : p.verificationData.localVerificationData;
      await Supabase.instance.client.functions.invoke(
        'activate-drama-pass',
        body: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'receipt_data': receiptData,
          'transaction_id': p.purchaseID ?? p.productID,
        },
      );
      onPassPurchase?.call(
        p.productID,
        const domain.PurchaseResult(status: domain.PurchaseStatus.success),
      );
    } catch (e) {
      onPassPurchase?.call(
        p.productID,
        domain.PurchaseResult(
          status: domain.PurchaseStatus.error,
          error: e.toString(),
        ),
      );
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
