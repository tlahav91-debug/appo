import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/creator_analytics_repository.dart';

final creatorAnalyticsRepositoryProvider =
    Provider<CreatorAnalyticsRepository>((_) => CreatorAnalyticsRepository());

final episodeAnalyticsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, submissionId) {
  return ref
      .read(creatorAnalyticsRepositoryProvider)
      .fetchEpisodeAnalytics(submissionId);
});
