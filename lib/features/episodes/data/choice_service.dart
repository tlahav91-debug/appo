import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final choiceServiceProvider = Provider<ChoiceService>((ref) {
  return ChoiceService(Supabase.instance.client);
});

class RecordChoiceResult {
  final bool success;
  final String? choiceId;
  final int coinsEarned;
  final int newBalance;
  final bool idempotent;
  final String? errorCode;
  final String? error;

  const RecordChoiceResult._({
    required this.success,
    this.choiceId,
    this.coinsEarned = 0,
    this.newBalance = 0,
    this.idempotent = false,
    this.errorCode,
    this.error,
  });

  factory RecordChoiceResult.ok(Map<String, dynamic> d) => RecordChoiceResult._(
        success: true,
        choiceId: d['choice_id'] as String?,
        coinsEarned: (d['coins_earned'] as num).toInt(),
        newBalance: (d['new_balance'] as num).toInt(),
        idempotent: d['idempotent'] == true,
      );

  factory RecordChoiceResult.err(String message, {String? code}) =>
      RecordChoiceResult._(success: false, error: message, errorCode: code);
}

class ChoiceService {
  final SupabaseClient _client;

  ChoiceService(this._client);

  String generateIdempotencyKey() {
    final rng = Random.secure();
    final bytes = List.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<RecordChoiceResult> recordChoice({
    required String episodeId,
    required String choiceId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'record-choice',
        body: {
          'episode_id': episodeId,
          'choice_id': choiceId,
          'idempotency_key': idempotencyKey,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return RecordChoiceResult.ok(data);
    } on FunctionException catch (e) {
      final body = e.details;
      if (e.status == 403 && body is Map && body['code'] == 'EPISODE_LOCKED') {
        return RecordChoiceResult.err('Episode not unlocked', code: 'EPISODE_LOCKED');
      }
      final msg = body is Map ? (body['error'] as String? ?? 'Unknown error') : e.toString();
      return RecordChoiceResult.err(msg);
    } catch (e) {
      return RecordChoiceResult.err(e.toString());
    }
  }
}
