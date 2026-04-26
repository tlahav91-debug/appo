import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/watch_progress_service.dart';
import '../domain/watch_progress.dart';

final watchProgressServiceProvider = Provider<WatchProgressService>((ref) => WatchProgressService());

final inProgressProvider = FutureProvider<List<WatchProgress>>((ref) async {
  final rows = await ref.read(watchProgressServiceProvider).fetchInProgress();
  return rows.map(WatchProgress.fromJson).toList();
});

final watchHistoryProvider = FutureProvider<List<WatchProgress>>((ref) async {
  final rows = await ref.read(watchProgressServiceProvider).fetchHistory();
  return rows.map(WatchProgress.fromJson).toList();
});
