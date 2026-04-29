import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/qa_repository.dart';
import '../domain/qa_session.dart';

final qaRepositoryProvider = Provider<QARepository>((_) => QARepository());

final myQASessionsProvider = FutureProvider.autoDispose<List<QASession>>((ref) {
  return ref.read(qaRepositoryProvider).fetchMySessions();
});

final upcomingQAProvider = FutureProvider.autoDispose<QASession?>((ref) {
  return ref.read(qaRepositoryProvider).fetchUpcomingForFollowed();
});

final creatorActiveQAProvider =
    FutureProvider.autoDispose.family<QASession?, String>((ref, creatorId) {
  return ref.read(qaRepositoryProvider).fetchActiveSessionForCreator(creatorId);
});

final qaSessionDetailProvider =
    FutureProvider.autoDispose.family<QASession?, String>((ref, sessionId) {
  return ref.read(qaRepositoryProvider).fetchSession(sessionId);
});

final sessionQuestionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, sessionId) {
  return ref.read(qaRepositoryProvider).fetchQuestionsForSession(sessionId);
});
