import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../features/ads/application/ad_provider.dart';
import '../../features/profile/application/profile_provider.dart';

class CoinRefillSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider).valueOrNull;
    final coinBalance = profile?.coins ?? 0;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoinRefillSheetBody(ref: ref, coinBalance: coinBalance),
    );
  }
}

class _CoinRefillSheetBody extends StatefulWidget {
  final WidgetRef ref;
  final int coinBalance;

  const _CoinRefillSheetBody({required this.ref, required this.coinBalance});

  @override
  State<_CoinRefillSheetBody> createState() => _CoinRefillSheetBodyState();
}

class _CoinRefillSheetBodyState extends State<_CoinRefillSheetBody> {
  bool _adLoading = false;
  bool _capReached = false;

  @override
  void initState() {
    super.initState();
    _checkCap();
  }

  Future<void> _checkCap() async {
    final canWatch = await widget.ref.read(adEnergyCapProvider.future);
    if (mounted) setState(() => _capReached = !canWatch);
  }

  Future<void> _watchAd() async {
    setState(() => _adLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final adService = widget.ref.read(rewardedAdServiceProvider);
      final rewarded = await adService.show(
        onReward: () async {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) return;
          await Supabase.instance.client.functions.invoke(
            'ad-reward',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'reward_type': 'coins'},
          );
          await recordAdGrant();
          widget.ref.invalidate(profileProvider);
        },
      );
      if (rewarded && mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('+5 🪙 added')));
      } else if (!rewarded && mounted) {
        setState(() => _adLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _adLoading = false);
        messenger.showSnackBar(SnackBar(content: Text('Ad failed: $e')));
      }
    }
  }

  void _goToShop() {
    Navigator.pop(context);
    GoRouter.of(context).push('/shop/gems');
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = widget.coinBalance;

    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderHi,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Need more coins?',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '$coinBalance coins',
                style: GoogleFonts.nunito(
                  color: coinBalance == 0 ? pink : textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _adLoading
                ? Container(
                    decoration: BoxDecoration(
                      gradient: pinkFull,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: textCol, strokeWidth: 2),
                    ),
                  )
                : _capReached
                    ? Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: borderHi),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Ad cap reached (3/3 today)',
                          style: GoogleFonts.sora(color: textDim, fontSize: 13),
                        ),
                      )
                    : GestureDetector(
                        onTap: _watchAd,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: pinkFull,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Watch an ad → +5 🪙',
                            style: GoogleFonts.nunito(
                              color: textCol,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _goToShop,
              child: Text(
                'Or get a coin pack',
                style: GoogleFonts.sora(color: textSec, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
