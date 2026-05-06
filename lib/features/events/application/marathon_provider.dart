import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/marathon_event.dart';

/// Active marathons with the current user's completion status
final activeMarathonsProvider =
    FutureProvider.autoDispose<List<MarathonEvent>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  final now = DateTime.now().toUtc().toIso8601String();
  final data = await client
      .from('marathon_events')
      .select('id, series_id, title, starts_at, ends_at, reward_coins, reward_collectible_id')
      .eq('is_active', true)
      .lte('starts_at', now)
      .gte('ends_at', now);

  if ((data as List).isEmpty) return [];

  // Batch-fetch completion status for this user
  Set<String> claimedIds = {};
  if (userId != null) {
    final completions = await client
        .from('marathon_completions')
        .select('marathon_id, reward_claimed_at')
        .eq('user_id', userId)
        .inFilter('marathon_id', data.map((e) => e['id'] as String).toList());
    claimedIds = (completions as List)
        .where((c) => c['reward_claimed_at'] != null)
        .map((c) => c['marathon_id'] as String)
        .toSet();
  }

  return data
      .map((j) => MarathonEvent.fromJson(
            j as Map<String, dynamic>,
            rewardClaimed: claimedIds.contains(j['id']),
          ))
      .toList();
});

/// Marathons active for a specific series
final seriesMarathonProvider =
    FutureProvider.autoDispose.family<MarathonEvent?, String>((ref, seriesId) async {
  final marathons = await ref.watch(activeMarathonsProvider.future);
  try {
    return marathons.firstWhere((m) => m.seriesId == seriesId);
  } catch (_) {
    return null;
  }
});
