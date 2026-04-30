import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchSubmissions() async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final res = await _db.functions.invoke(
      'get-admin-submissions',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (res.data == null) throw Exception('No data');
    final data = res.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['submissions'] as List);
  }

  Future<void> approveSubmission({
    required String submissionId,
    required bool isFree,
    required int episodeOrder,
    String? seriesId,
    String? newSeriesTitle,
  }) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    await _db.functions.invoke(
      'admin-approve-content',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'submission_id': submissionId,
        'is_free': isFree,
        'episode_order': episodeOrder,
        if (seriesId != null) 'series_id': seriesId,
        if (newSeriesTitle != null) 'new_series_title': newSeriesTitle,
      },
    );
  }

  Future<void> rejectSubmission({
    required String submissionId,
    required String reason,
  }) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    await _db.functions.invoke(
      'admin-reject-content',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'submission_id': submissionId, 'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> fetchPayouts() async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final res = await _db.functions.invoke(
      'get-admin-payouts',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (res.data == null) throw Exception('No data');
    final data = res.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['payouts'] as List);
  }

  Future<void> markPayoutPaid(String requestId) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    await _db.functions.invoke(
      'admin-mark-payout-paid',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'request_id': requestId},
    );
  }
}
