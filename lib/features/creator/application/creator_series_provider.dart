import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/creator_series_repository.dart';

final creatorSeriesRepositoryProvider =
    Provider<CreatorSeriesRepository>((_) => CreatorSeriesRepository());

final mySeriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(creatorSeriesRepositoryProvider).fetchMySeries();
});

final seriesSubmissionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, seriesId) {
  return ref
      .read(creatorSeriesRepositoryProvider)
      .fetchSubmissionsForSeries(seriesId);
});
