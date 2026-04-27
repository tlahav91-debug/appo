import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/application/profile_provider.dart';
import '../application/creator_provider.dart';

class CreatorAnalyticsScreen extends ConsumerWidget {
  const CreatorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Guard: non-creators should not see this screen
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile != null && !profile.isCreator) {
      return Scaffold(
        backgroundColor: bgDeep,
        body: Center(
          child: Text('Creator access only.', style: GoogleFonts.sora(color: textDim)),
        ),
      );
    }

    final analyticsAsync = ref.watch(creatorAnalyticsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Creator Analytics',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: Text('Error loading analytics', style: GoogleFonts.sora(color: textDim))),
        data: (data) {
          final summary = data['summary'] as Map<String, dynamic>;
          final episodes = data['episodes'] as List;

          final totalViews = (summary['total_views'] as num).toInt();
          final avgCompletion = (summary['avg_completion_pct'] as num).toDouble();
          final totalEarnings = (summary['total_earnings_usd'] as num).toDouble();

          return RefreshIndicator(
            color: gold,
            onRefresh: () async => ref.invalidate(creatorAnalyticsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary stat cards row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Views',
                        value: totalViews.toString(),
                        icon: '👁️',
                        gradient: purpleGrad,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Completion',
                        value: '${avgCompletion.toStringAsFixed(1)}%',
                        icon: '📊',
                        gradient: cyanGrad,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Total Earnings',
                        value: '\$${totalEarnings.toStringAsFixed(2)}',
                        icon: '💰',
                        gradient: goldGrad,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Episode Performance',
                  style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (episodes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'No episodes yet. Upload content to see analytics.',
                      style: GoogleFonts.sora(color: textDim, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...episodes.map((e) => _EpisodeStatRow(episode: e as Map<String, dynamic>)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w900, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.sora(color: textCol, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EpisodeStatRow extends StatelessWidget {
  final Map<String, dynamic> episode;
  const _EpisodeStatRow({required this.episode});

  @override
  Widget build(BuildContext context) {
    final epNumber = episode['episode_number'] as num;
    final title = episode['title'] as String;
    final viewCount = (episode['view_count'] as num).toInt();
    final avgCompletion = (episode['avg_completion_pct'] as num).toDouble();
    final earnings = (episode['total_earnings_usd'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EP${epNumber.toInt()} · $title',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(label: '👁️ $viewCount views', color: purple),
              const SizedBox(width: 8),
              _StatChip(label: '📊 ${avgCompletion.toStringAsFixed(1)}%', color: cyan),
              const SizedBox(width: 8),
              _StatChip(label: '💰 \$${earnings.toStringAsFixed(2)}', color: gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
