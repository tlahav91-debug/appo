import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';

class RewardedAdService {
  RewardedAd? _ad;
  bool _isLoading = false;
  bool get isReady => _ad != null;

  Future<void> load() async {
    if (_isLoading || _ad != null) return;
    _isLoading = true;
    await RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
        },
      ),
    );
  }

  Future<bool> show({required Future<void> Function() onReward}) async {
    if (_ad == null) return false;
    final ad = _ad!;
    _ad = null; // consume immediately to prevent double-show
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        ad.dispose();
        load(); // preload next
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        ad.dispose();
        load();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, reward) async {
      await onReward();
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
