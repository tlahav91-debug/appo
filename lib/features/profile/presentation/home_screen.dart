import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/stars.dart';
import '../../club/application/club_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(userClubProvider);
    final club = clubAsync.valueOrNull;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Events + Journey quick-access row
              SizedBox(
                height: 80,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 0),
                  child: Row(
                    children: [
                      // EventsCard
                      GestureDetector(
                        onTap: () => context.push('/events'),
                        child: Container(
                          width: 160,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF1A0A2E), Color(0xFFFF2D78)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('⚡', style: TextStyle(fontSize: 28)),
                              Text('Live Events', style: GoogleFonts.nunito(color: textCol, fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                      // JourneyCard
                      GestureDetector(
                        onTap: () => context.push('/journey'),
                        child: Container(
                          width: 160,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0A1A2E), Color(0xFF4A90D9)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('🗺️', style: TextStyle(fontSize: 28)),
                              Text('Journey', style: GoogleFonts.nunito(color: textCol, fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Watch Club card
              if (clubAsync.hasValue)
                club != null
                    ? _ClubCard(
                        name: club.name,
                        memberCount: club.memberCount,
                        onTap: () => context.push('/club/${club.id}'),
                      )
                    : _JoinClubCta(
                        onTap: () => context.push('/club/search'),
                      ),
              if (clubAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: cyan, strokeWidth: 2)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final String name;
  final int memberCount;
  final VoidCallback onTap;

  const _ClubCard(
      {required this.name, required this.memberCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: cyanGrad,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgDeep.withAlpha(180),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$memberCount member${memberCount != 1 ? 's' : ''} · tap to view',
                      style: GoogleFonts.sora(color: textSec, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: textSec),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinClubCta extends StatelessWidget {
  final VoidCallback onTap;

  const _JoinClubCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cyanDim),
        ),
        child: Row(
          children: [
            const Text('👥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join a Watch Club',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Watch together, climb the leaderboard',
                    style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textDim, size: 18),
          ],
        ),
      ),
    );
  }
}
