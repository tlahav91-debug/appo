import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/application/profile_provider.dart';

final _earningsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {'month_total': 0.0, 'pending_payout': 0.0};

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

  // Month-to-date earnings
  final earnings = await Supabase.instance.client
      .from('creator_earnings')
      .select('energy_gate_revenue_usd, subscription_share_usd')
      .eq('creator_id', userId)
      .gte('date', monthStart);

  double monthTotal = 0;
  for (final row in (earnings as List)) {
    monthTotal += (row['energy_gate_revenue_usd'] as num).toDouble();
    monthTotal += (row['subscription_share_usd'] as num).toDouble();
  }

  // Pending payout
  final payouts = await Supabase.instance.client
      .from('creator_payouts')
      .select('amount_usd, status')
      .eq('creator_id', userId)
      .inFilter('status', ['pending', 'processing']);

  double pendingTotal = 0;
  for (final row in (payouts as List)) {
    pendingTotal += (row['amount_usd'] as num).toDouble();
  }

  // Payout history
  final history = await Supabase.instance.client
      .from('creator_payouts')
      .select('amount_usd, status, period_start, period_end, created_at')
      .eq('creator_id', userId)
      .order('created_at', ascending: false)
      .limit(12);

  return {
    'month_total': monthTotal,
    'pending_payout': pendingTotal,
    'history': history as List,
  };
});

class CreatorEarningsScreen extends ConsumerWidget {
  const CreatorEarningsScreen({super.key});

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

    final summaryAsync = ref.watch(_earningsSummaryProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Creator Earnings',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: Text('Error loading earnings', style: GoogleFonts.sora(color: textDim))),
        data: (data) {
          final monthTotal = (data['month_total'] as double);
          final pendingPayout = (data['pending_payout'] as double);
          final history = data['history'] as List;

          return RefreshIndicator(
            color: gold,
            onRefresh: () async => ref.invalidate(_earningsSummaryProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Month-to-date card
                _EarningsCard(
                  label: 'This Month',
                  amount: monthTotal,
                  gradient: goldGrad,
                  icon: '💰',
                ),
                const SizedBox(height: 12),
                // Pending payout card
                _EarningsCard(
                  label: 'Pending Payout',
                  amount: pendingPayout,
                  gradient: purpleGrad,
                  icon: '⏳',
                ),
                const SizedBox(height: 24),
                Text(
                  'Payout History',
                  style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Text('No payouts yet.', style: GoogleFonts.sora(color: textDim, fontSize: 13))
                else
                  ...history.map((p) => _PayoutRow(payout: p as Map<String, dynamic>)),
                const SizedBox(height: 24),
                Text(
                  'Platform take: 40% · Your share: 60% · Min payout: \$10 USD',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final double amount;
  final LinearGradient gradient;
  final String icon;

  const _EarningsCard({
    required this.label,
    required this.amount,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.sora(color: textCol, fontSize: 13)),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ],
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
    final status = payout['status'] as String;
    final amount = (payout['amount_usd'] as num).toDouble();
    final start = payout['period_start'] as String;
    final end = payout['period_end'] as String;

    Color statusColor;
    switch (status) {
      case 'paid': statusColor = green; break;
      case 'failed': statusColor = pink; break;
      default: statusColor = gold; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Text(
                  '$start → $end',
                  style: GoogleFonts.sora(color: textSec, fontSize: 12),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: GoogleFonts.sora(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
