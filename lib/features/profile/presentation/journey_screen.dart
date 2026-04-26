import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';
import '../application/profile_provider.dart';
import '../application/journey_provider.dart';
import '../domain/fan_level.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(journeyStatsProvider);
    final thresholds =
        ref.watch(fanLevelThresholdsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          RefreshIndicator(
            color: pink,
            backgroundColor: surface,
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(journeyStatsProvider);
              await ref
                  .read(journeyStatsProvider.future)
                  .catchError((_) {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: [
                // Header
                Text(
                  'My Journey',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your drama watching progress',
                  style: GoogleFonts.sora(color: textSec, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Profile card
                profileAsync.when(
                  loading: () => const _SkeletonCard(height: 120),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    final fanLevel = FanLevel.fromProfile(
                      profile.xp,
                      profile.fanLevel,
                      thresholds,
                    );
                    return _ProfileCard(
                      username: profile.username ?? 'Player',
                      avatarUrl: profile.avatarUrl,
                      fanLevel: profile.fanLevel,
                      xp: profile.xp,
                      progressFraction: fanLevel.progressFraction,
                      xpToNext: fanLevel.xpToNextLevel,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Stats grid
                Text(
                  'Stats',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  loading: () => const _SkeletonCard(height: 160),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load',
                      style: GoogleFonts.sora(color: textDim),
                    ),
                  ),
                  data: (stats) => _StatsGrid(stats: stats),
                ),
                const SizedBox(height: 24),

                // Milestones
                Text(
                  'Milestones',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  loading: () => const _SkeletonCard(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => _MilestoneList(stats: stats),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final int fanLevel;
  final int xp;
  final double progressFraction;
  final int xpToNext;

  const _ProfileCard({
    required this.username,
    this.avatarUrl,
    required this.fanLevel,
    required this.xp,
    required this.progressFraction,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: purpleGrad,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardHi,
              border: Border.all(color: borderHi, width: 2),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: textDim,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: textDim, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level $fanLevel · $xp XP',
                  style: GoogleFonts.sora(color: textSec, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // XP progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressFraction.clamp(0.0, 1.0),
                    backgroundColor: surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(pink),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  xpToNext > 0 ? '$xpToNext XP to next level' : 'Max level',
                  style:
                      GoogleFonts.sora(color: textDim, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final JourneyStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          emoji: '🎬',
          label: 'Episodes Watched',
          value: '${stats.episodesWatched}',
          gradient: pinkGrad,
        ),
        _StatCard(
          emoji: '🔥',
          label: 'Day Streak',
          value: '${stats.currentStreak}',
          gradient: goldGrad,
        ),
        _StatCard(
          emoji: '⚡',
          label: 'Best Race Rank',
          value: stats.bestRaceRank > 0 ? '#${stats.bestRaceRank}' : '—',
          gradient: purpleGrad,
        ),
        _StatCard(
          emoji: '📋',
          label: 'Saved Shows',
          value: '${stats.savedShows}',
          gradient: cyanGrad,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Gradient gradient;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.sora(color: textSec, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestones
// ---------------------------------------------------------------------------

class _MilestoneList extends StatelessWidget {
  final JourneyStats stats;
  const _MilestoneList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final milestones = [
      _Milestone('First Episode', '🎬', stats.episodesWatched >= 1),
      _Milestone('Binge Watcher (10 eps)', '📺', stats.episodesWatched >= 10),
      _Milestone('Drama Addict (50 eps)', '🎭', stats.episodesWatched >= 50),
      _Milestone('3-Day Streak', '🔥', stats.currentStreak >= 3),
      _Milestone('7-Day Streak', '🌟', stats.currentStreak >= 7),
      _Milestone('Race Competitor', '⚡', stats.bestRaceRank > 0),
      _Milestone(
        'Top 10 Racer',
        '🏆',
        stats.bestRaceRank > 0 && stats.bestRaceRank <= 10,
      ),
      _Milestone('Collector (5 saved)', '📋', stats.savedShows >= 5),
    ];

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: milestones.length,
        separatorBuilder: (_, __) =>
            const Divider(color: border, height: 1),
        itemBuilder: (_, i) {
          final m = milestones[i];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  m.emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: m.unlocked ? null : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    m.label,
                    style: GoogleFonts.nunito(
                      color: m.unlocked ? textCol : textDim,
                      fontWeight: m.unlocked
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (m.unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Earned',
                      style: GoogleFonts.sora(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.lock_outline, color: textDim, size: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Milestone {
  final String label;
  final String emoji;
  final bool unlocked;
  const _Milestone(this.label, this.emoji, this.unlocked);
}

// ---------------------------------------------------------------------------
// Skeleton loader
// ---------------------------------------------------------------------------

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
