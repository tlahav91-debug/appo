import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gem_shop_service.dart';
import '../domain/gem_pack.dart';

final gemShopServiceProvider = Provider<GemShopService>((ref) => GemShopService());

final gemPacksProvider = FutureProvider<List<GemPack>>((ref) {
  return ref.read(gemShopServiceProvider).fetchPacks();
});

final purchaseNotifierProvider =
    AsyncNotifierProvider.autoDispose<PurchaseNotifier, PurchaseResult?>(
  PurchaseNotifier.new,
);

class PurchaseNotifier extends AutoDisposeAsyncNotifier<PurchaseResult?> {
  @override
  Future<PurchaseResult?> build() async => null;

  Future<void> buy(String productId) async {
    state = const AsyncValue.loading();
    final result = await ref.read(gemShopServiceProvider).purchase(productId);
    state = AsyncValue.data(result);
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final result = await ref.read(gemShopServiceProvider).restorePurchases();
    state = AsyncValue.data(result);
  }
}
