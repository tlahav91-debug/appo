import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/inbox_item.dart';

class InboxService {
  final _client = Supabase.instance.client;

  Future<List<InboxItem>> fetchItems() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await _client
        .from('inbox_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List).map((e) => InboxItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({bool claimed, int coinsEarned, int gemsEarned, String? error})> claimItem(String itemId) async {
    try {
      final res = await _client.functions.invoke('claim-inbox-reward', body: {'item_id': itemId});
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) return (claimed: false, coinsEarned: 0, gemsEarned: 0, error: data['error'] as String);
      return (claimed: true, coinsEarned: data['coins_earned'] as int? ?? 0, gemsEarned: data['gems_earned'] as int? ?? 0, error: null);
    } catch (e) {
      return (claimed: false, coinsEarned: 0, gemsEarned: 0, error: e.toString());
    }
  }
}
