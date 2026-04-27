import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/inbox/application/inbox_provider.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/profile/domain/fan_level.dart';
import '../../features/profile/domain/profile.dart';
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
              const Spacer(),
              // Coins
              CurrencyDisplay(amount: profile.coins, emoji: '🪙', color: gold),
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
          ],
        ),
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
              color: Colors.white,
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
