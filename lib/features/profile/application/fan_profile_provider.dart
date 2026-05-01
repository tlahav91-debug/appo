import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fanProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  final db = Supabase.instance.client;

  // Query 1-2 and 4 in parallel; query 3 is two-step (FK mismatch workaround)
  final results = await Future.wait([
    db
        .from('public_fan_profiles') // view: id, username, avatar_url, fan_level, xp only
        .select('id, username, avatar_url, fan_level, xp')
        .eq('id', userId)
        .single(),
    db
        .from('user_collectibles')
        .select('collectibles(id, name, image_url, rarity)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false)
        .limit(6),
    db
        .from('creator_follows')
        .select('creator_id')
        .eq('follower_id', userId)
        .limit(8),
    db
        .from('daily_check_ins')
        .select('checked_in_at')
        .eq('user_id', userId)
        .order('checked_in_at', ascending: false)
        .limit(60),
  ]);

  // Step 2 of creator_follows join: look up creator_profiles by ids
  final followRows = results[2] as List<dynamic>;
  final creatorIds = followRows
      .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
      .toList();

  List<dynamic> creatorProfiles = [];
  if (creatorIds.isNotEmpty) {
    creatorProfiles = await db
        .from('creator_profiles')
        .select('id, display_name')
        .inFilter('id', creatorIds);
  }

  final creatorMap = {
    for (final c in creatorProfiles)
      (c as Map<String, dynamic>)['id'] as String:
          c['display_name'] as String? ?? '',
  };

  final follows = followRows
      .map((r) => {
            'creator_id': (r as Map<String, dynamic>)['creator_id'],
            'creator_profiles': {
              'display_name': creatorMap[(r)['creator_id'] as String] ?? '',
            },
          })
      .toList();

  return {
    'profile': results[0] as Map<String, dynamic>,
    'collectibles': results[1] as List<dynamic>,
    'follows': follows,
    'check_ins': results[3] as List<dynamic>,
  };
});
