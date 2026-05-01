import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fanProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  final db = Supabase.instance.client;

  final results = await Future.wait([
    db
        .from('profiles')
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
        .select('creator_id, creator_profiles(display_name)')
        .eq('follower_id', userId)
        .limit(8),
    db
        .from('daily_check_ins')
        .select('checked_in_at')
        .eq('user_id', userId)
        .order('checked_in_at', ascending: false)
        .limit(60),
  ]);

  return {
    'profile': results[0] as Map<String, dynamic>,
    'collectibles': results[1] as List<dynamic>,
    'follows': results[2] as List<dynamic>,
    'check_ins': results[3] as List<dynamic>,
  };
});
