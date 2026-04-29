import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../shared/widgets/hud.dart';
import '../../../features/profile/application/profile_provider.dart';
import '../application/referral_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeController = TextEditingController();
  String? _redeemError;
  bool _redeemSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _redeemError = null;
      _redeemSuccess = false;
    });

    final notifier = ref.read(redeemReferralProvider.notifier);
    final error = await notifier.redeem(code);

    if (!mounted) return;

    if (error == null) {
      setState(() => _redeemSuccess = true);
      ref.invalidate(profileProvider);
    } else {
      setState(() => _redeemError = error);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code copied!',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
        ),
        backgroundColor: surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(referralCodeProvider);
    final redeemState = ref.watch(redeemReferralProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: code == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              children: [
                // Title
                Text(
                  'Invite Friends 🎁',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle
                Text(
                  'Share your code and earn 100 🪙 each',
                  style: GoogleFonts.nunito(
                    color: textSec,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // "Your Code" label
                Text(
                  'Your Code',
                  style: GoogleFonts.nunito(
                    color: textSec,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // Code display container
                Container(
                  decoration: BoxDecoration(
                    gradient: goldGrad,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        code,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () => _copyCode(code),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Share button
                Container(
                  decoration: BoxDecoration(
                    gradient: pinkFull,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ref.read(analyticsProvider).capture('referral_share_tapped');
                        Share.share(
                          'Use my code $code to join Appo and earn 100 🪙!\nhttps://appo.app/ref/$code',
                          subject: 'Join me on Appo!',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Share with Friends',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                const Divider(color: border),
                const SizedBox(height: 24),

                // Redeem section label
                Text(
                  'Have a referral code?',
                  style: GoogleFonts.nunito(
                    color: textSec,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),

                // Code input + Redeem button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          hintStyle: GoogleFonts.nunito(color: textDim),
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: pink, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: cyanGrad,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: redeemState.isLoading ? null : _redeem,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: redeemState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Redeem',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Error message
                if (_redeemError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _redeemError!,
                    style: GoogleFonts.nunito(
                      color: pink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Success message
                if (_redeemSuccess) ...[
                  const SizedBox(height: 12),
                  Text(
                    '🎉 +100 coins added!',
                    style: GoogleFonts.nunito(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
