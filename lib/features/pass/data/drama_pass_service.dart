import '../../shop/domain/gem_pack.dart';

class DramaPassService {
  Future<bool> checkEntitlement() async => false;

  Future<String?> fetchLocalizedPrice() async => null;

  Future<PurchaseResult> subscribe() async =>
      const PurchaseResult(status: PurchaseStatus.error, error: 'Drama Pass unavailable.');

  Future<PurchaseResult> restoreAndCheck() async =>
      const PurchaseResult(status: PurchaseStatus.error, error: 'No active Drama Pass found.');
}
