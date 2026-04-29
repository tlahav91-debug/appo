import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/qa_session.dart';

class QARepository {
  final _db = Supabase.instance.client;

  Future<List<QASession>> fetchMySessions() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _db
        .from('creator_qa_sessions')
        .select()
        .eq('creator_id', uid)
        .order('scheduled_at', ascending: false);
    return (data as List)
        .map((j) => QASession.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<QASession?> fetchSession(String sessionId) async {
    final data = await _db
        .from('creator_qa_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    return data == null ? null : QASession.fromJson(data as Map<String, dynamic>);
  }

  Future<QASession?> fetchUpcomingForFollowed() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final follows = await _db
        .from('creator_follows')
        .select('creator_id')
        .eq('follower_id', uid);
    final ids = (follows as List).map((f) => f['creator_id'] as String).toList();
    if (ids.isEmpty) return null;
    final data = await _db
        .from('creator_qa_sessions')
        .select()
        .inFilter('creator_id', ids)
        .inFilter('status', ['scheduled', 'live'])
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return data == null ? null : QASession.fromJson(data as Map<String, dynamic>);
  }

  Future<QASession?> fetchActiveSessionForCreator(String creatorId) async {
    final data = await _db
        .from('creator_qa_sessions')
        .select()
        .eq('creator_id', creatorId)
        .inFilter('status', ['scheduled', 'live'])
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return data == null ? null : QASession.fromJson(data as Map<String, dynamic>);
  }

  Future<String> createSession(
    String title,
    DateTime scheduledAt,
    List<QAMessage> messages,
  ) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final row = await _db
        .from('creator_qa_sessions')
        .insert({
          'creator_id': uid,
          'title': title,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    final sessionId = row['id'] as String;
    if (messages.isNotEmpty) {
      await _db.from('creator_qa_messages').insert(
            messages
                .map((m) => {
                      'session_id': sessionId,
                      'body': m.body,
                      'delay_seconds': m.delaySeconds,
                      'position': m.position,
                    })
                .toList(),
          );
    }
    return sessionId;
  }

  Future<void> submitQuestion(String sessionId, String body) async {
    final userId = _db.auth.currentUser!.id;
    await _db.from('creator_qa_questions').insert({
      'session_id': sessionId,
      'fan_id': userId,
      'body': body,
    });
  }

  Future<List<Map<String, dynamic>>> fetchQuestionsForSession(String sessionId) async {
    final data = await _db
        .from('creator_qa_questions')
        .select('id, body, fan_id, created_at')
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> pinQuestion(String sessionId, String questionId) async {
    await _db
        .from('creator_qa_sessions')
        .update({'pinned_question_id': questionId})
        .eq('id', sessionId);
  }

  Future<Map<String, dynamic>?> fetchPinnedQuestion(String sessionId) async {
    final data = await _db
        .from('creator_qa_sessions')
        .select('pinned_question_id, creator_qa_questions(id, body, fan_id)')
        .eq('id', sessionId)
        .maybeSingle();
    if (data == null) return null;
    final nested = data['creator_qa_questions'];
    if (nested == null) return null;
    return Map<String, dynamic>.from(nested as Map);
  }

  RealtimeChannel joinChannel(String sessionId) {
    return _db.channel('qa:$sessionId');
  }

  Future<void> deleteSession(String id) async {
    await _db.from('creator_qa_sessions').delete().eq('id', id);
  }
}
