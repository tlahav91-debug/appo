import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/application/profile_provider.dart';

// Reads referral code from already-loaded profile
final referralCodeProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).valueOrNull?.referralCode;
});

// Notifier for redeem action
class RedeemReferralNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> redeem(String code) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.functions.invoke(
        'redeem-referral',
        body: {'code': code.trim().toUpperCase()},
      );
      state = const AsyncData(null);
      return null; // success
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      final msg = e.toString();
      if (msg.contains('SELF_REFERRAL')) return 'You cannot redeem your own code.';
      if (msg.contains('ALREADY_REDEEMED')) return 'You have already redeemed a referral code.';
      if (msg.contains('CODE_NOT_FOUND')) return 'Code not found. Check and try again.';
      return 'Something went wrong. Please try again.';
    }
  }
}

final redeemReferralProvider = AsyncNotifierProvider<RedeemReferralNotifier, void>(
  RedeemReferralNotifier.new,
);
