import 'package:shared_preferences/shared_preferences.dart';
import '../domain/gem_pack.dart';
import '../domain/starter_pack.dart';

const _kDismissedKey = 'starter_pack_dismissed';

class StarterPackService {
  Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDismissedKey) ?? false;
  }

  Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissedKey, true);
  }

  Future<StarterPackOffer?> fetchOffer() async =>
      const StarterPackOffer(localizedPrice: '\$2.99');

  Future<PurchaseResult> purchase() async =>
      const PurchaseResult(status: PurchaseStatus.error, error: 'Starter Pack unavailable.');
}
