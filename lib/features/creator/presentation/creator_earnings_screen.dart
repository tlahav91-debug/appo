import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_earnings_provider.dart';

class CreatorEarningsScreen extends ConsumerStatefulWidget {
  const CreatorEarningsScreen({super.key});

  @override
  ConsumerState<CreatorEarningsScreen> createState() =>
      _CreatorEarningsScreenState();
}

class _CreatorEarningsScreenState extends ConsumerState<CreatorEarningsScreen> {
  bool _thisMonth = true;
  final Set<String> _expandedSeries = {};
  bool _requesting = false;

  Future<void> _requestPayout(int balance) async {
    if (balance < 500 || _requesting) return;
    setState(() => _requesting = true);
    try {
      await ref
          .read(creatorEarningsRepositoryProvider)
          .requestPayout(balance);
      ref.invalidate(payoutRequestsProvider);
      ref.invalidate(earningsSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payout requested ✓',
              style: GoogleFonts.sora(color: textCol)),
          backgroundColor: surface,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.sora(color: textCol)),
          backgroundColor: lava,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(earningsSummaryProvider);
    ref.invalidate(earningsBySeriesProvider(true));
    ref.invalidate(earningsBySeriesProvider(false));
    ref.invalidate(payoutRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(earningsSummaryProvider);
    final earningsAsync = ref.watch(earningsBySeriesProvider(_thisMonth));
    final payoutsAsync = ref.watch(payoutRequestsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Creator Earnings',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        color: gold,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Balance card
            summaryAsync.when(
              loading: () => _balanceCardLoading(),
              error: (_, __) => _balanceCardLoading(),
              data: (summary) {
                final balance = summary['total_scrolls'] ?? 0;
                final gems = balance ~/ 100;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: goldGrad,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$balance',
                        style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w900,
                            fontSize: 40),
                      ),
                      Text(
                        'scrolls',
                        style: GoogleFonts.sora(
                            color: textCol.withOpacity(0.7), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '≈ $gems gems 💎',
                        style: GoogleFonts.sora(
                            color: textCol.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // This Month / All Time toggle
            Row(
              children: [
                _ToggleTab(
                  label: 'This Month',
                  selected: _thisMonth,
                  onTap: () => setState(() => _thisMonth = true),
                ),
                const SizedBox(width: 24),
                _ToggleTab(
                  label: 'All Time',
                  selected: !_thisMonth,
                  onTap: () => setState(() => _thisMonth = false),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Request Payout button
            summaryAsync.when(
              loading: () => _payoutButtonShell(0, enabled: false),
              error: (_, __) => _payoutButtonShell(0, enabled: false),
              data: (summary) {
                final balance = summary['total_scrolls'] ?? 0;
                final canPayout = balance >= 500 && !_requesting;
                return GestureDetector(
                  onTap: canPayout ? () => _requestPayout(balance) : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: canPayout ? pinkGrad : null,
                      color: canPayout ? null : card,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: _requesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: textCol, strokeWidth: 2))
                        : Text(
                            balance >= 500
                                ? 'Request Payout ($balance scrolls)'
                                : 'Request Payout (min 500 scrolls)',
                            style: GoogleFonts.nunito(
                                color: canPayout ? textCol : textDim,
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Payout history
            payoutsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (payouts) {
                if (payouts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payout History',
                        style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    ...payouts.map((p) => _PayoutRow(payout: p)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Earnings by series label
            Text('Earnings by Series',
                style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 8),

            // Earnings list
            earningsAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: gold, strokeWidth: 2),
              )),
              error: (_, __) => Text('Failed to load earnings',
                  style: GoogleFonts.sora(color: textDim, fontSize: 13)),
              data: (rows) {
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No earnings yet. Earnings appear once episodes go live.',
                      style: GoogleFonts.sora(color: textDim, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Group by series_id
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final row in rows) {
                  final sid = row['series_id'] as String? ?? 'unknown';
                  grouped.putIfAbsent(sid, () => []).add(row);
                }

                return Column(
                  children: grouped.entries.map((entry) {
                    final seriesId = entry.key;
                    final episodes = entry.value;
                    final seriesTitle =
                        (episodes.first['series'] as Map?)?['title']
                                as String? ??
                            'Untitled Series';
                    final totalStreams = episodes.fold<int>(
                        0, (s, e) => s + (e['stream_count'] as int? ?? 0));
                    final totalScrolls = episodes.fold<int>(
                        0, (s, e) => s + (e['revenue_scrolls'] as int? ?? 0));
                    final isExpanded = _expandedSeries.contains(seriesId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              if (isExpanded) {
                                _expandedSeries.remove(seriesId);
                              } else {
                                _expandedSeries.add(seriesId);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(seriesTitle,
                                        style: GoogleFonts.nunito(
                                            color: textCol,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ),
                                  const Icon(Icons.play_arrow,
                                      color: textDim, size: 12),
                                  const SizedBox(width: 2),
                                  Text('$totalStreams',
                                      style: GoogleFonts.sora(
                                          color: textDim, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  Text('$totalScrolls scrolls',
                                      style: GoogleFonts.sora(
                                          color: gold, fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: textDim,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            ...episodes.map((ep) {
                              final sub = ep['content_submissions'] as Map?;
                              final epNum =
                                  sub?['episode_number'] as int? ?? 0;
                              final epTitle =
                                  sub?['title'] as String? ?? 'Episode';
                              final streams = ep['stream_count'] as int? ?? 0;
                              final scrolls =
                                  ep['revenue_scrolls'] as int? ?? 0;
                              final subId =
                                  ep['submission_id'] as String? ?? '';
                              return GestureDetector(
                                onTap: subId.isNotEmpty
                                    ? () => context.push(
                                        '/creator/analytics/episode/$subId')
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: border),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: card,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('E$epNum',
                                            style: GoogleFonts.sora(
                                                color: textCol,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 9)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(epTitle,
                                            style: GoogleFonts.sora(
                                                color: textCol, fontSize: 12)),
                                      ),
                                      Text('$streams',
                                          style: GoogleFonts.sora(
                                              color: textDim, fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Text('$scrolls',
                                          style: GoogleFonts.sora(
                                              color: gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.bar_chart_outlined,
                                          color: textDim, size: 12),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCardLoading() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
            child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
      );

  Widget _payoutButtonShell(int balance, {required bool enabled}) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          'Request Payout (min 500 scrolls)',
          style: GoogleFonts.nunito(
              color: textDim, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      );
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.sora(
                  color: selected ? gold : textDim,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal)),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            color: selected ? gold : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final Map<String, dynamic> payout;
  const _PayoutRow({required this.payout});

  @override
  Widget build(BuildContext context) {
    final status = payout['status'] as String? ?? 'pending';
    final amount = payout['amount_scrolls'] as int? ?? 0;
    final requestedAt = payout['requested_at'] as String? ?? '';
    final date = requestedAt.isNotEmpty
        ? requestedAt.substring(0, 10)
        : '';

    final (grad, useBorder) = switch (status) {
      'processing' => (purpleGrad, false),
      'paid' => (greenGrad, false),
      _ => (null, true),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$amount scrolls',
                    style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                if (date.isNotEmpty)
                  Text(date,
                      style: GoogleFonts.sora(color: textSec, fontSize: 11)),
              ],
            ),
          ),
          useBorder
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderHi),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status,
                      style: GoogleFonts.sora(color: textDim, fontSize: 10)),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status,
                      style: GoogleFonts.sora(
                          color: textCol,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
        ],
      ),
    );
  }
}
