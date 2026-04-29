import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/creator_earnings_repository.dart';

final creatorEarningsRepositoryProvider =
    Provider<CreatorEarningsRepository>((_) => CreatorEarningsRepository());

final earningsSummaryProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.read(creatorEarningsRepositoryProvider).fetchEarningsSummary();
});

final earningsBySeriesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, bool>(
        (ref, thisMonth) {
  return ref
      .read(creatorEarningsRepositoryProvider)
      .fetchEarningsBySeries(thisMonth: thisMonth);
});

final payoutRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(creatorEarningsRepositoryProvider).fetchPayoutRequests();
});
