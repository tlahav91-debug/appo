import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final creatorAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {'summary': {}, 'episodes': []};

  final rows = await Supabase.instance.client
      .from('creator_episode_stats')
      .select()
      .eq('creator_id', userId)
      .order('view_count', ascending: false);

  final list = rows as List;
  int totalViews = 0;
  double totalCompletionSum = 0;
  double totalEarnings = 0;

  for (final r in list) {
    totalViews += (r['view_count'] as num).toInt();
    totalCompletionSum += (r['avg_completion_pct'] as num).toDouble();
    totalEarnings += (r['total_earnings_usd'] as num).toDouble();
  }

  final avgCompletion = list.isEmpty ? 0.0 : totalCompletionSum / list.length;

  return {
    'summary': {
      'total_views': totalViews,
      'avg_completion_pct': avgCompletion,
      'total_earnings_usd': totalEarnings,
    },
    'episodes': list,
  };
});

final creatorProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final data = await Supabase.instance.client
      .from('creator_profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
  return data;
});

class ApplyCreatorNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> apply({
    required String displayName,
    required String bio,
    required String whyCreate,
  }) async {
    state = const AsyncLoading();
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return 'Not logged in';
      final res = await Supabase.instance.client.functions.invoke(
        'apply-creator',
        body: {
          'display_name': displayName,
          'bio': bio,
          'why_create': whyCreate,
        },
      );
      if (res.status != 200) {
        final err = (res.data as Map?)?['error'] as String? ?? 'Unknown error';
        state = const AsyncData(null);
        return err;
      }
      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }
}

final applyCreatorProvider = AsyncNotifierProvider<ApplyCreatorNotifier, void>(
  ApplyCreatorNotifier.new,
);
