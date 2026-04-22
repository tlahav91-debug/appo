import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/profile/application/profile_provider.dart';
import '../../features/profile/domain/profile.dart';
import 'currency_display.dart';

class HUD extends ConsumerWidget implements PreferredSizeWidget {
  const HUD({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (p) => _HudContent(profile: p, ref: ref),
      loading: () => profileAsync.hasValue
          ? _HudContent(profile: profileAsync.value!, ref: ref)
          : const _HudSkeleton(),
      error: (_, __) => const _HudSkeleton(),
    );
  }
}

class _HudContent extends StatelessWidget {
  final Profile profile;
  final WidgetRef ref;

  const _HudContent({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // XP bar
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (profile.xp / 100).clamp(0.0, 1.0),
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
          // Settings
          GestureDetector(
            onTap: () => _showSettings(context),
            child: const Icon(Icons.settings_outlined, color: textSec, size: 22),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
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
