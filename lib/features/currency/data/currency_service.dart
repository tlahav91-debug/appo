import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService(Supabase.instance.client);
});

class EarnCoinsResult {
  final bool success;
  final int coinsEarned;
  final int newBalance;
  final bool idempotent;
  final String? error;

  const EarnCoinsResult._({
    required this.success,
    this.coinsEarned = 0,
    this.newBalance = 0,
    this.idempotent = false,
    this.error,
  });

  factory EarnCoinsResult.ok(Map<String, dynamic> d, {bool idempotent = false}) =>
      EarnCoinsResult._(
        success: true,
        coinsEarned: (d['coins_earned'] as num).toInt(),
        newBalance: (d['new_balance'] as num).toInt(),
        idempotent: idempotent,
      );

  factory EarnCoinsResult.err(String message) =>
      EarnCoinsResult._(success: false, error: message);
}

class CurrencyService {
  final SupabaseClient _client;

  CurrencyService(this._client);

  Future<EarnCoinsResult> earnCoins({
    required String choiceId,
    required String episodeId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'earn-coins',
        body: {
          'choice_id': choiceId,
          'episode_id': episodeId,
          'idempotency_key': idempotencyKey,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return EarnCoinsResult.ok(data, idempotent: data['idempotent'] == true);
    } on FunctionException catch (e) {
      final body = e.details;
      if (body is Map) {
        return EarnCoinsResult.err(body['error'] as String? ?? 'Unknown error');
      }
      return EarnCoinsResult.err(e.toString());
    } catch (e) {
      return EarnCoinsResult.err(e.toString());
    }
  }
}
