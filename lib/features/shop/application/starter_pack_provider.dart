import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'iap_provider.dart';
import '../data/starter_pack_service.dart';
import '../domain/gem_pack.dart';
import '../domain/starter_pack.dart';

final starterPackServiceProvider = Provider<StarterPackService>((ref) {
  return StarterPackService(ref.read(iapServiceProvider));
});

final starterPackOfferProvider = FutureProvider<StarterPackOffer?>((ref) {
  return ref.read(starterPackServiceProvider).fetchOffer();
});

final starterPackPurchaseNotifierProvider =
    AsyncNotifierProvider.autoDispose<StarterPackPurchaseNotifier, PurchaseResult?>(
  StarterPackPurchaseNotifier.new,
);

class StarterPackPurchaseNotifier
    extends AutoDisposeAsyncNotifier<PurchaseResult?> {
  @override
  Future<PurchaseResult?> build() async => null;

  Future<void> buy() async {
    state = const AsyncValue.loading();
    final result = await ref.read(starterPackServiceProvider).purchase();
    state = AsyncValue.data(result);
  }
}
