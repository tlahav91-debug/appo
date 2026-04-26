import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/meta_item.dart';

class MetaService {
  final _client = Supabase.instance.client;

  Future<Set<String>> fetchUnlockedIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};
    final res = await _client
        .from('meta_unlocks')
        .select('item_id')
        .eq('user_id', userId);
    return {for (final r in (res as List)) r['item_id'] as String};
  }

  Future<MetaLoadout> fetchLoadout() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const MetaLoadout();
    final res = await _client
        .from('user_meta_profile')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return const MetaLoadout();
    return MetaLoadout.fromJson(res as Map<String, dynamic>);
  }

  Future<({bool unlocked, int gemsRemaining, String? error})> unlock(
      String itemType, String itemId) async {
    try {
      final res = await _client.functions.invoke(
        'unlock-meta-item',
        body: {'item_type': itemType, 'item_id': itemId},
      );
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) {
        return (unlocked: false, gemsRemaining: 0, error: data['error'] as String);
      }
      return (
        unlocked: true,
        gemsRemaining: data['gems_remaining'] as int? ?? 0,
        error: null,
      );
    } catch (e) {
      return (unlocked: false, gemsRemaining: 0, error: e.toString());
    }
  }

  Future<bool> equip({String? roomId, String? outfitId, String? moodId}) async {
    try {
      await _client.functions.invoke(
        'equip-meta-item',
        body: {
          if (roomId != null) 'room_id': roomId,
          if (outfitId != null) 'outfit_id': outfitId,
          if (moodId != null) 'mood_id': moodId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
