import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/ad_config.dart';
import '../data/ad_service.dart';
import 'rewarded_ad_service.dart';

export '../data/ad_service.dart' show AdShowResult;

// ---------------------------------------------------------------------------
// Legacy provider — used by the existing Watch-Ad flow in EnergyGate
// ---------------------------------------------------------------------------
final adServiceProvider = Provider.autoDispose<AdService>((ref) {
  final service = AdService(adUnitId: kRewardedAdUnitId);
  service.loadAd();
  return service;
});

// ---------------------------------------------------------------------------
// PRD-038: new RewardedAdService provider (google_mobile_ads v2 API)
// ---------------------------------------------------------------------------
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final service = RewardedAdService();
  service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Checks the daily rewarded-ad cap (max 3 per calendar day).
/// Returns true if the user can still watch an ad today.
final adEnergyCapProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_date') ?? '';
  if (savedDate != today) return true; // new day — cap resets
  final count = prefs.getInt('rewarded_ad_count') ?? 0;
  return count < 3;
});

/// Records one ad grant for today (increments local counter).
Future<void> recordAdGrant() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_date') ?? '';
  if (savedDate != today) {
    await prefs.setString('rewarded_ad_date', today);
    await prefs.setInt('rewarded_ad_count', 1);
  } else {
    final count = prefs.getInt('rewarded_ad_count') ?? 0;
    await prefs.setInt('rewarded_ad_count', count + 1);
  }
}

/// Calls the increment-energy Edge Function to credit +5 energy server-side.
Future<void> grantAdEnergy() async {
  await Supabase.instance.client.functions.invoke(
    'increment-energy',
    body: {'amount': 5},
  );
}
