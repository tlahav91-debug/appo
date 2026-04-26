import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'iap_service.dart';

final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService();
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});
