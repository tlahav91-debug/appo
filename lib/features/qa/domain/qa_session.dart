enum QAStatus { scheduled, live, ended }

class QASession {
  final String id;
  final String creatorId;
  final String title;
  final DateTime scheduledAt;
  final QAStatus status;

  const QASession({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.scheduledAt,
    required this.status,
  });

  factory QASession.fromJson(Map<String, dynamic> j) => QASession(
        id: j['id'] as String,
        creatorId: j['creator_id'] as String,
        title: j['title'] as String,
        scheduledAt: DateTime.parse(j['scheduled_at'] as String).toLocal(),
        status: QAStatus.values.byName(j['status'] as String),
      );
}

class QAMessage {
  final String id;
  final String sessionId;
  final String body;
  final int delaySeconds;
  final int position;

  const QAMessage({
    required this.id,
    required this.sessionId,
    required this.body,
    required this.delaySeconds,
    required this.position,
  });

  factory QAMessage.fromJson(Map<String, dynamic> j) => QAMessage(
        id: j['id'] as String,
        sessionId: j['session_id'] as String? ?? '',
        body: j['body'] as String,
        delaySeconds: (j['delay_seconds'] as num).toInt(),
        position: (j['position'] as num).toInt(),
      );
}
