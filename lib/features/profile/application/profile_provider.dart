import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    final repo = ref.read(profileRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Serve cache immediately while fetching live data
    final cached = await repo.getCachedProfile();
    if (cached != null) {
      // Schedule live fetch without blocking initial render
      Future.microtask(() async {
        try {
          final live = await repo.fetchProfile(userId);
          state = AsyncValue.data(live);
        } catch (_) {
          // Keep cached value on fetch failure
        }
      });
      return cached;
    }

    return repo.fetchProfile(userId);
  }

  Future<void> signOut() async {
    final repo = ref.read(profileRepositoryProvider);
    await Supabase.instance.client.auth.signOut();
    await repo.clearCache();
  }
}
