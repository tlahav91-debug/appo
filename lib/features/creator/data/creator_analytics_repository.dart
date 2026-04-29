import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorAnalyticsRepository {
  final _db = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchEpisodeAnalytics(
      String submissionId) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final res = await _db.functions.invoke(
      'get-episode-analytics',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'submission_id': submissionId},
    );
    if (res.data == null) throw Exception('No data returned');
    return Map<String, dynamic>.from(res.data as Map);
  }
}
