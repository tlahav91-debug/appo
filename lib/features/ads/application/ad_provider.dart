import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/ad_config.dart';
import '../data/ad_service.dart';

export '../data/ad_service.dart' show AdShowResult;

final adServiceProvider = Provider.autoDispose<AdService>((ref) {
  final service = AdService(adUnitId: kRewardedAdUnitId);
  service.loadAd();
  return service;
});
