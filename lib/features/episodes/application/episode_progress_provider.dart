import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EpProgress {
  final bool completed;
  final int progressPct;

  const EpProgress({required this.completed, required this.progressPct});
}

/// Map of episode_id → EpProgress for a given series, for the current user.
final seriesProgressProvider = FutureProvider.family<Map<String, EpProgress>, String>(
  (ref, seriesId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {};

    final data = await Supabase.instance.client
        .from('watch_progress')
        .select('episode_id, completed, progress_pct')
        .eq('user_id', userId)
        .eq('series_id', seriesId);

    final rows = (data as List).cast<Map<String, dynamic>>();
    return {
      for (final r in rows)
        r['episode_id'] as String: EpProgress(
          completed: r['completed'] as bool? ?? false,
          progressPct: (r['progress_pct'] as num?)?.toInt() ?? 0,
        )
    };
  },
);
