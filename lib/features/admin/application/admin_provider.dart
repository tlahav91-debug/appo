import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((_) => AdminRepository());

final adminSubmissionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchSubmissions();
});

final adminPayoutsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchPayouts();
});
