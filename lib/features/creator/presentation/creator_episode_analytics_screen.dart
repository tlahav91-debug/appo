import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_analytics_provider.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${_months[d.month - 1]} ${d.day}';
  } catch (_) {
    return iso;
  }
}

class CreatorEpisodeAnalyticsScreen extends ConsumerWidget {
  final String submissionId;
  const CreatorEpisodeAnalyticsScreen({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(episodeAnalyticsProvider(submissionId));

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Episode Analytics',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: dataAsync.when(
        loading: () => const _LoadingShimmer(),
        error: (_, __) => Center(
          child: Text('Failed to load analytics',
              style: GoogleFonts.sora(color: textDim, fontSize: 13)),
        ),
        data: (data) => _AnalyticsBody(data: data),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnalyticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final episode = data['episode'] as Map<String, dynamic>? ?? {};
    final analytics =
        (data['analytics'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    final totalViews = summary['total_views'] as int? ?? 0;
    final totalScrolls = summary['total_scrolls'] as int? ?? 0;
    final pct = (summary['avg_completion_pct'] as num?)?.toDouble() ?? 0.0;
    final status = episode['status'] as String? ?? 'draft';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Episode header
        Text(episode['series_title'] as String? ?? '',
            style: GoogleFonts.sora(color: textSec, fontSize: 12)),
        const SizedBox(height: 4),
        Text(episode['title'] as String? ?? '',
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        _StatusBadge(status: status),

        const SizedBox(height: 16),

        // Summary cards row
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                gradient: cyanGrad,
                icon: Icons.play_arrow,
                value: '$totalViews',
                label: 'Views',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                gradient: purpleGrad,
                icon: Icons.check_circle_outline,
                value: '${pct.toStringAsFixed(1)}%',
                label: 'Completion',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                gradient: goldGrad,
                icon: Icons.toll_outlined,
                value: '$totalScrolls',
                label: 'Scrolls',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Completion bar
        Row(
          children: [
            Text('Avg Completion',
                style: GoogleFonts.sora(color: textSec, fontSize: 12)),
            const Spacer(),
            Text('${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.sora(color: gold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: surface,
            child: FractionallySizedBox(
              widthFactor: (pct / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                  color: pct < 40
                      ? pink
                      : pct < 70
                          ? gold
                          : green),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('<40% needs work',
                style: GoogleFonts.sora(color: pink, fontSize: 10)),
            const Spacer(),
            Text('70%+ great',
                style: GoogleFonts.sora(color: green, fontSize: 10)),
          ],
        ),

        const SizedBox(height: 24),

        Text('Daily History',
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),

        if (analytics.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No analytics yet. Check back after your first views.',
                style: GoogleFonts.sora(color: textDim, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...analytics.map((row) {
            final views = row['view_count'] as int? ?? 0;
            final completion =
                (row['avg_completion_pct'] as num?)?.toDouble() ?? 0.0;
            final scrolls = row['revenue_scrolls'] as int? ?? 0;
            final dateStr = _fmtDate(row['date'] as String? ?? '');

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(dateStr,
                        style:
                            GoogleFonts.sora(color: textSec, fontSize: 12)),
                  ),
                  const Spacer(),
                  const Icon(Icons.play_arrow, color: textDim, size: 12),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    child: Text('$views',
                        style: GoogleFonts.sora(
                            color: textCol, fontSize: 12),
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle_outline,
                      color: purple, size: 12),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    child: Text('${completion.toStringAsFixed(0)}%',
                        style: GoogleFonts.sora(
                            color: purple, fontSize: 12),
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 12),
                  Text('$scrolls🪙',
                      style: GoogleFonts.sora(color: gold, fontSize: 12)),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),

        // Insights
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights',
                  style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              ..._buildInsights(analytics, summary),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInsights(
      List<Map<String, dynamic>> analytics, Map<String, dynamic> summary) {
    final insights = <Widget>[];
    final pct =
        (summary['avg_completion_pct'] as num?)?.toDouble() ?? 0.0;
    final totalScrolls = summary['total_scrolls'] as int? ?? 0;

    if (analytics.isNotEmpty) {
      final top = analytics.reduce((a, b) =>
          (a['view_count'] as int? ?? 0) >= (b['view_count'] as int? ?? 0)
              ? a
              : b);
      final topDate = _fmtDate(top['date'] as String? ?? '');
      final topViews = top['view_count'] as int? ?? 0;
      insights.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('📈 Top day: $topDate · $topViews views',
            style: GoogleFonts.sora(color: textSec, fontSize: 12)),
      ));
    }

    if (pct >= 55) {
      insights.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('✓ Above platform average completion (55%)',
            style: GoogleFonts.sora(color: green, fontSize: 12)),
      ));
    } else if (pct == 0.0 && analytics.isNotEmpty) {
      insights.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
            '⚠ No completions recorded — check your video is processing correctly',
            style: GoogleFonts.sora(color: gold, fontSize: 12)),
      ));
    } else if (pct < 40) {
      insights.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
            '⚠ Low completion — consider a stronger opening scene',
            style: GoogleFonts.sora(color: gold, fontSize: 12)),
      ));
    }

    if (totalScrolls > 0) {
      insights.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
            '🪙 $totalScrolls scrolls earned across ${analytics.length} days',
            style: GoogleFonts.sora(color: textSec, fontSize: 12)),
      ));
    }

    if (insights.isEmpty) {
      insights.add(Text('No insights yet — check back after more views.',
          style: GoogleFonts.sora(color: textDim, fontSize: 12)));
    }

    return insights;
  }
}

class _SummaryCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.gradient,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textCol, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          Text(label,
              style: GoogleFonts.sora(
                  color: textCol.withOpacity(0.8), fontSize: 10)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, grad, useBorder) = switch (status) {
      'submitted' => ('Under Review', purpleGrad, false),
      'approved' => ('Live ✓', greenGrad, false),
      'rejected' => ('Rejected', pinkGrad, false),
      _ => ('Draft', null, true),
    };

    if (useBorder) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: borderHi),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.sora(color: textDim, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.sora(
              color: textCol, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _shimmer(60),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _shimmer(80)),
            const SizedBox(width: 8),
            Expanded(child: _shimmer(80)),
            const SizedBox(width: 8),
            Expanded(child: _shimmer(80)),
          ],
        ),
        const SizedBox(height: 16),
        _shimmer(8),
        const SizedBox(height: 24),
        _shimmer(44),
        const SizedBox(height: 8),
        _shimmer(44),
        const SizedBox(height: 8),
        _shimmer(44),
        const SizedBox(height: 8),
        _shimmer(44),
      ],
    );
  }

  Widget _shimmer(double height) => Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
