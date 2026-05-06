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

// ---------------------------------------------------------------------------
// PRD-097: Independent daily cap trackers for energy vs coin ads
// Energy cap: 3/day — Coin cap: 2/day
// ---------------------------------------------------------------------------

/// Returns true if the user can still watch an energy ad today (cap: 3/day).
final adEnergyCapProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_energy_date') ?? '';
  if (savedDate != today) return true;
  final count = prefs.getInt('rewarded_ad_energy_count') ?? 0;
  return count < 3;
});

/// Returns true if the user can still watch a coin ad today (cap: 2/day).
final adCoinCapProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_coins_date') ?? '';
  if (savedDate != today) return true;
  final count = prefs.getInt('rewarded_ad_coins_count') ?? 0;
  return count < 2;
});

/// Records one energy ad grant for today (increments local energy counter).
Future<void> recordEnergyAdGrant() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_energy_date') ?? '';
  if (savedDate != today) {
    await prefs.setString('rewarded_ad_energy_date', today);
    await prefs.setInt('rewarded_ad_energy_count', 1);
  } else {
    final count = prefs.getInt('rewarded_ad_energy_count') ?? 0;
    await prefs.setInt('rewarded_ad_energy_count', count + 1);
  }
}

/// Records one coin ad grant for today (increments local coin counter).
Future<void> recordCoinAdGrant() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final savedDate = prefs.getString('rewarded_ad_coins_date') ?? '';
  if (savedDate != today) {
    await prefs.setString('rewarded_ad_coins_date', today);
    await prefs.setInt('rewarded_ad_coins_count', 1);
  } else {
    final count = prefs.getInt('rewarded_ad_coins_count') ?? 0;
    await prefs.setInt('rewarded_ad_coins_count', count + 1);
  }
}

/// Calls the increment-energy Edge Function to credit +5 energy server-side.
Future<void> grantAdEnergy() async {
  await Supabase.instance.client.functions.invoke(
    'increment-energy',
    body: {'amount': 5},
  );
}
