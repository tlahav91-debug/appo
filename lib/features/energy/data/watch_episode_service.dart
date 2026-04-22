import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/watch_result.dart';

class WatchEpisodeService {
  final SupabaseClient _client;

  WatchEpisodeService(this._client);

  Future<WatchResult> watchEpisode({
    required String episodeId,
    required String requestId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'watch-episode',
        body: {'episode_id': episodeId, 'request_id': requestId},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['already_unlocked'] == true) {
        return WatchResult.alreadyUnlocked();
      }

      return WatchResult.success(
        (data['energy_remaining'] as num?)?.toInt() ?? 0,
      );
    } on FunctionException catch (e) {
      final body = e.details;
      if (e.status == 402 && body is Map && body['code'] == 'INSUFFICIENT_ENERGY') {
        return WatchResult.insufficientEnergy(
          current: (body['current'] as num).toInt(),
          required: (body['required'] as num).toInt(),
        );
      }
      return WatchResult.error(e.toString());
    } catch (e) {
      return WatchResult.error(e.toString());
    }
  }

  Future<({bool success, int energyRemaining, int adViewsToday})> claimAdReward({
    required String rewardType,
  }) async {
    final response = await _client.functions.invoke(
      'ad-reward',
      body: {'reward_type': rewardType},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      success: true,
      energyRemaining: (data['energy_remaining'] as num).toInt(),
      adViewsToday: (data['ad_views_today'] as num).toInt(),
    );
  }

  Future<({bool success, int energyRemaining, int gemsRemaining})> claimGemRefill() async {
    final response = await _client.functions.invoke('gem-refill', body: {});
    final data = response.data as Map<String, dynamic>;
    return (
      success: true,
      energyRemaining: (data['energy_remaining'] as num).toInt(),
      gemsRemaining: (data['gems_remaining'] as num).toInt(),
    );
  }
}
