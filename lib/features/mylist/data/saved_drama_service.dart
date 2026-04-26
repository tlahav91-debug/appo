import 'package:supabase_flutter/supabase_flutter.dart';

class SavedDramaService {
  final _client = Supabase.instance.client;

  Future<bool> toggle(String seriesId) async {
    try {
      final res = await _client.functions.invoke('toggle-saved-drama', body: {'series_id': seriesId});
      return res.data['saved'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSaved() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await _client
        .from('saved_dramas')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
