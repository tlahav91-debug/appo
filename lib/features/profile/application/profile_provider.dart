import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/notifications/notification_provider.dart';
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
  bool _hasTrackedSession = false;

  @override
  Future<Profile> build() async {
    ref.onDispose(() {
      _realtimeSub?.cancel();
    });

    final repo = ref.read(profileRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');


    // Serve cache immediately while fetching live data
    final cached = await repo.getCachedProfile();
    if (cached != null) {
      Future.microtask(() async {
        try {
          final live = await repo.fetchProfile(userId);
          state = AsyncValue.data(live);
          _identifyAndTrack(userId, live);
          _setupPushNotifications();
          _subscribeRealtime(userId, repo);
          _syncPassEntitlement(userId);
          _claimDailyPassBonusIfEligible(live);
        } catch (_) {}
      });
      return cached;
    }

    final live = await repo.fetchProfile(userId);
    _identifyAndTrack(userId, live);
    _setupPushNotifications();
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
    if (!_hasTrackedSession) {
      analytics.capture('session_started');
      _hasTrackedSession = true;
    }
  }

  void _setupPushNotifications() {
    final service = ref.read(notificationServiceProvider);
    Future.microtask(() async {
      try {
        await service.initialize();
        await service.registerCurrentToken();
      } catch (_) {}
    });
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

  Future<void> _syncPassEntitlement(String userId) async {
    // Drama Pass entitlement sync — reserved for future IAP integration
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
    ref.read(analyticsProvider).reset();
    await Supabase.instance.client.auth.signOut();
    ref.invalidateSelf();
  }
}
