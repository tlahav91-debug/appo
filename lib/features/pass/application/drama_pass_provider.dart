import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shop/application/iap_provider.dart';
import '../../shop/domain/gem_pack.dart';
import '../data/drama_pass_service.dart';

final dramaPassServiceProvider = Provider<DramaPassService>((ref) {
  return DramaPassService(ref.read(iapServiceProvider));
});

final passLocalizedPriceProvider = FutureProvider<String?>((ref) {
  return ref.read(dramaPassServiceProvider).fetchLocalizedPrice();
});

final passSubscribeNotifierProvider =
    AsyncNotifierProvider.autoDispose<PassSubscribeNotifier, PurchaseResult?>(
  PassSubscribeNotifier.new,
);

class PassSubscribeNotifier extends AutoDisposeAsyncNotifier<PurchaseResult?> {
  @override
  Future<PurchaseResult?> build() async => null;

  Future<void> subscribe() async {
    state = const AsyncValue.loading();
    final result = await ref.read(dramaPassServiceProvider).subscribe();
    state = AsyncValue.data(result);
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final result = await ref.read(dramaPassServiceProvider).restoreAndCheck();
    state = AsyncValue.data(result);
  }
}
