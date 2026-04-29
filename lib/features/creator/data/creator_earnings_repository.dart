import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorEarningsRepository {
  final _db = Supabase.instance.client;

  Future<Map<String, int>> fetchEarningsSummary() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return {};

    final earnings = await _db
        .from('creator_earnings')
        .select('revenue_scrolls, period')
        .eq('creator_id', uid)
        .not('submission_id', 'is', null);

    final payouts = await _db
        .from('payout_requests')
        .select('amount_scrolls, status')
        .eq('creator_id', uid)
        .inFilter('status', ['processing', 'paid']);

    final allTime = (earnings as List)
        .fold<int>(0, (sum, e) => sum + (e['revenue_scrolls'] as int? ?? 0));
    final paidOut = (payouts as List)
        .fold<int>(0, (sum, p) => sum + (p['amount_scrolls'] as int? ?? 0));

    final now = DateTime.now();
    final thisMonth = (earnings).where((e) {
      final raw = e['period'] as String?;
      if (raw == null) return false;
      final period = DateTime.parse(raw);
      return period.year == now.year && period.month == now.month;
    }).fold<int>(0, (sum, e) => sum + (e['revenue_scrolls'] as int? ?? 0));

    return {
      'total_scrolls': allTime - paidOut,
      'paid_scrolls': paidOut,
      'this_month_scrolls': thisMonth,
      'all_time_scrolls': allTime,
    };
  }

  Future<List<Map<String, dynamic>>> fetchEarningsBySeries(
      {required bool thisMonth}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    var query = _db
        .from('creator_earnings')
        .select(
            'series_id, submission_id, stream_count, revenue_scrolls, period, series(title), content_submissions(title, episode_number)')
        .eq('creator_id', uid)
        .not('submission_id', 'is', null);

    if (thisMonth) {
      final now = DateTime.now();
      final periodStart =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      query = query.eq('period', periodStart);
    }

    final data =
        await query.order('series_id').order('submission_id');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> fetchPayoutRequests() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _db
        .from('payout_requests')
        .select('id, amount_scrolls, status, requested_at, paid_at')
        .eq('creator_id', uid)
        .order('requested_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> requestPayout(int amountScrolls) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    await _db.from('payout_requests').insert({
      'creator_id': uid,
      'amount_scrolls': amountScrolls,
    });
  }
}
