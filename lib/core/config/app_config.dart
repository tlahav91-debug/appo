import 'dart:io';

class AppConfig {
  // Test ad unit IDs — replace with prod IDs before release
  static const String rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'  // AdMob test rewarded (Android)
      : 'ca-app-pub-3940256099942544/1712485313'; // AdMob test rewarded (iOS)
}
