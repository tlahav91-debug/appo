import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile> {
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  @override
  Future<Profile> build() async {
    ref.onDispose(() {
      _realtimeSub?.cancel();
    });

    final repo = ref.read(profileRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Link RevenueCat identity to Supabase user ID
    await Purchases.logIn(userId);

    // Serve cache immediately while fetching live data
    final cached = await repo.getCachedProfile();
    if (cached != null) {
      Future.microtask(() async {
        try {
          final live = await repo.fetchProfile(userId);
          state = AsyncValue.data(live);
          _subscribeRealtime(userId, repo);
        } catch (_) {
          // Keep cached value on fetch failure
        }
      });
      return cached;
    }

    final live = await repo.fetchProfile(userId);
    _subscribeRealtime(userId, repo);
    return live;
  }

  void _subscribeRealtime(String userId, ProfileRepository repo) {
    _realtimeSub?.cancel();
    _realtimeSub = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((rows) {
          if (rows.isEmpty) return;
          final updated = Profile.fromJson(rows.first);
          repo.cacheProfile(updated);
          state = AsyncValue.data(updated);
        });
  }

  Future<void> signOut() async {
    final repo = ref.read(profileRepositoryProvider);
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    await repo.clearCache();
    await Purchases.logOut();
    await Supabase.instance.client.auth.signOut();
    ref.invalidateSelf();
  }
}
