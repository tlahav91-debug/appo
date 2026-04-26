class GemPack {
  final String productId;
  final int gemsAmount;
  final String title;
  final String localizedPrice;
  final String? badge;

  const GemPack({
    required this.productId,
    required this.gemsAmount,
    required this.title,
    required this.localizedPrice,
    this.badge,
  });
}

enum PurchaseStatus { idle, loading, success, cancelled, error }

class PurchaseResult {
  final PurchaseStatus status;
  final String? error;
  final String? productId;

  const PurchaseResult({required this.status, this.error, this.productId});
}
