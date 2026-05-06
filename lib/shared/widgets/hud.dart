import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../features/creator/application/notifications_provider.dart';
import '../../features/inbox/application/inbox_provider.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/profile/domain/fan_level.dart';
import '../../features/profile/domain/profile.dart';
import '../../features/rewards/application/streak_provider.dart';
import 'coin_refill_sheet.dart';
import 'currency_display.dart';

class HUD extends ConsumerWidget implements PreferredSizeWidget {
  const HUD({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56 + 28); // status row + VIP bar slot

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (p) => _HudContent(profile: p),
      loading: () => profileAsync.hasValue
          ? _HudContent(profile: profileAsync.value!)
          : const _HudSkeleton(),
      error: (_, __) => const _HudSkeleton(),
    );
  }
}

class _HudContent extends ConsumerWidget {
  final Profile profile;

  const _HudContent({required this.profile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholds = ref.watch(fanLevelThresholdsProvider).valueOrNull ?? [];
    final fanLevel = FanLevel.fromProfile(profile.xp, profile.fanLevel, thresholds);
    final currentStreak = ref.watch(streakStatusProvider).valueOrNull?.currentStreak ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: bgDeep.withOpacity(0.95),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cardHi,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderHi, width: 1.5),
                ),
                child: profile.avatarUrl != null
                    ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: textSec, size: 20),
              ),
              const SizedBox(width: 8),
              // Level badge
              Text(
                'Lv.${profile.fanLevel}',
                style: GoogleFonts.nunito(
                  color: gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (profile.dramaPassActive) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push('/pass'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: purpleGrad,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PASS',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              // XP bar — fraction computed from real thresholds
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fanLevel.progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: purpleGrad,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              if (currentStreak >= 1) ...[
                const SizedBox(width: 6),
                Text(
                  '🔥$currentStreak',
                  style: GoogleFonts.nunito(
                    color: gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              // Coins — tap opens refill sheet when balance is zero
              GestureDetector(
                onTap: profile.coins == 0
                    ? () => CoinRefillSheet.show(context, ref)
                    : null,
                child: CurrencyDisplay(amount: profile.coins, emoji: '🪙', color: gold),
              ),
              const SizedBox(width: 12),
              // Gems
              CurrencyDisplay(amount: profile.gems, emoji: '💎', color: cyan),
              const SizedBox(width: 12),
              // Mail icon with badge
              Consumer(builder: (context, ref, _) {
                final unread = ref.watch(unreadCountProvider);
                return GestureDetector(
                  onTap: () => InboxScreen.show(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text('📬', style: TextStyle(fontSize: 20)),
                      if (unread > 0)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(color: pink, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: GoogleFonts.nunito(color: textCol, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 12),
              // Notification bell
              Consumer(
                builder: (context, ref, _) {
                  final unread = ref.watch(unreadNotificationCountProvider);
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: textCol),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 6, top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: GoogleFonts.sora(color: bgDeep, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              // Settings
              GestureDetector(
                onTap: () => _showSettings(context, ref),
                child: const Icon(Icons.settings_outlined, color: textSec, size: 22),
              ),
            ],
          ),
        ),
        if (profile.dramaPassActive)
          const _VipBar()
        else
          const SizedBox(height: 28),
      ],
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: borderHi,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: cyan),
              title: Text('Invite Friends 🎁', style: GoogleFonts.sora(color: textCol, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                context.push('/referral');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: cyan),
              title: Text(
                'Edit Profile',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile/edit');
              },
            ),
            if (profile.isCreator)
              ListTile(
                leading: const Icon(Icons.movie_creation_outlined, color: gold),
                title: Text(
                  'Creator Studio',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/creator/status');
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.movie_creation_outlined, color: purple),
                title: Text(
                  'Become a Creator 🎬',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/creator/apply');
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: cyan),
              title: Text(
                'Notifications 🔔',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: pink),
              title: Text(
                'Sign out',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(profileProvider.notifier).signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: lava),
              title: Text(
                'Delete Account',
                style: GoogleFonts.nunito(
                  color: lava,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountConfirmation(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  await ref.read(profileProvider.notifier).signOut();
  if (context.mounted) context.go('/auth');
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not signed in');
      await Supabase.instance.client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Deletion failed. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Account?',
        style: GoogleFonts.nunito(color: lava, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently deletes your profile, progress, coins, gems, and all data. This cannot be undone.',
            style: GoogleFonts.sora(color: textCol, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'If you have an active Drama Pass, cancel it in your App Store / Play Store settings before deleting.',
            style: GoogleFonts.sora(color: textDim, fontSize: 12),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.sora(color: lava, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.nunito(color: textDim)),
        ),
        TextButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: lava, strokeWidth: 2))
              : Text('Delete Account', style: GoogleFonts.nunito(color: lava, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
    );
  }
}

class _VipBar extends StatelessWidget {
  final int vipTier;

  const _VipBar({this.vipTier = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 20,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(children: [
        FractionallySizedBox(
          widthFactor: 1.0, // 100% for tier 1
          child: Container(
            decoration: BoxDecoration(
              gradient: pinkFull,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Center(
          child: Text(
            'DRAMA PASS ACTIVE',
            style: GoogleFonts.nunito(
              color: textCol,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ]),
    );
  }
}

class _HudSkeleton extends StatelessWidget {
  const _HudSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: bgDeep.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: cardHi),
          Spacer(),
        ],
      ),
    );
  }
}
