import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdShowResult { rewarded, dismissed, unavailable, failed }

class AdService {
  final String adUnitId;
  RewardedAd? _ad;
  bool _loading = false;

  AdService({required this.adUnitId});

  bool get isReady => _ad != null;

  Future<void> loadAd() async {
    if (_loading || _ad != null) return;
    _loading = true;
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  Future<AdShowResult> showAd() async {
    if (_ad == null) return AdShowResult.unavailable;

    final ad = _ad!;
    _ad = null;

    final completer = Completer<AdShowResult>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!completer.isCompleted) {
          completer.complete(
              rewarded ? AdShowResult.rewarded : AdShowResult.dismissed);
        }
        // Pre-load next ad
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!completer.isCompleted) completer.complete(AdShowResult.failed);
        loadAd();
      },
    );

    ad.show(onUserEarnedReward: (_, __) => rewarded = true);
    return completer.future;
  }
}
