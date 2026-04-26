import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../data/profile_repository.dart';
import '../domain/fan_level.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final fanLevelThresholdsProvider = FutureProvider<List<FanLevelThreshold>>((ref) {
  return ref.read(profileRepositoryProvider).fetchFanLevelThresholds();
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

    await Purchases.logIn(userId);

    // Serve cache immediately while fetching live data
    final cached = await repo.getCachedProfile();
    if (cached != null) {
      Future.microtask(() async {
        try {
          final live = await repo.fetchProfile(userId);
          state = AsyncValue.data(live);
          _identifyAndTrack(userId, live);
          _subscribeRealtime(userId, repo);
          _syncPassEntitlement(userId);
          _claimDailyPassBonusIfEligible(live);
        } catch (_) {}
      });
      return cached;
    }

    final live = await repo.fetchProfile(userId);
    _identifyAndTrack(userId, live);
    _subscribeRealtime(userId, repo);
    _syncPassEntitlement(userId);
    _claimDailyPassBonusIfEligible(live);
    return live;
  }

  void _identifyAndTrack(String userId, Profile profile) {
    final analytics = ref.read(analyticsProvider);
    analytics.identify(userId, {
      'fan_level': profile.fanLevel,
      'drama_pass_active': profile.dramaPassActive,
    });
    analytics.capture('session_started');
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

  // Reconcile drama_pass_active with RevenueCat entitlement truth
  Future<void> _syncPassEntitlement(String userId) async {
    try {
      final info = await Purchases.getCustomerInfo();
      final rcActive = info.entitlements.active.containsKey('drama_pass');
      final dbActive = state.valueOrNull?.dramaPassActive ?? false;
      if (rcActive != dbActive) {
        await Supabase.instance.client
            .from('profiles')
            .update({'drama_pass_active': rcActive})
            .eq('id', userId);
      }
    } catch (_) {}
  }

  // Fire-and-forget daily pass bonus; Realtime stream picks up the energy change
  void _claimDailyPassBonusIfEligible(Profile profile) {
    if (!profile.passBonusClaimableToday) return;
    Future.microtask(() async {
      try {
        await Supabase.instance.client.functions.invoke('claim-pass-bonus', body: {});
      } catch (_) {}
    });
  }

  Future<void> signOut() async {
    final repo = ref.read(profileRepositoryProvider);
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    await repo.clearCache();
    await Purchases.logOut();
    ref.read(analyticsProvider).reset();
    await Supabase.instance.client.auth.signOut();
    ref.invalidateSelf();
  }
}
