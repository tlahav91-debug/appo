import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();
  return Supabase.instance.client
      .from('creator_notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50)
      .map((rows) => List<Map<String, dynamic>>.from(rows));
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifs.where((n) => n['is_read'] == false).length;
});
