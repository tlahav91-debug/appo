import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
