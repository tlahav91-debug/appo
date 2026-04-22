import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/watch_result.dart';

enum AdRewardError { capReached, unavailable }
enum GemRefillError { insufficientGems, energyFull, unknown }

class AdRewardResult {
  final bool success;
  final String rewardType;
  final int rewardAmount;
  final int energyRemaining;
  final int adViewsToday;
  final AdRewardError? error;

  const AdRewardResult._({
    required this.success,
    this.rewardType = '',
    this.rewardAmount = 0,
    this.energyRemaining = 0,
    this.adViewsToday = 0,
    this.error,
  });

  factory AdRewardResult.ok(Map<String, dynamic> d) => AdRewardResult._(
        success: true,
        rewardType: d['reward_type'] as String,
        rewardAmount: (d['reward_amount'] as num).toInt(),
        energyRemaining: (d['energy_remaining'] as num).toInt(),
        adViewsToday: (d['ad_views_today'] as num).toInt(),
      );

  factory AdRewardResult.err(AdRewardError e) =>
      AdRewardResult._(success: false, error: e);
}

class GemRefillResult {
  final bool success;
  final int energyRemaining;
  final int gemsRemaining;
  final GemRefillError? error;

  const GemRefillResult._({
    required this.success,
    this.energyRemaining = 0,
    this.gemsRemaining = 0,
    this.error,
  });

  factory GemRefillResult.ok(Map<String, dynamic> d) => GemRefillResult._(
        success: true,
        energyRemaining: (d['energy_remaining'] as num).toInt(),
        gemsRemaining: (d['gems_remaining'] as num).toInt(),
      );

  factory GemRefillResult.err(GemRefillError e) =>
      GemRefillResult._(success: false, error: e);
}

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
      if (data['already_unlocked'] == true) return WatchResult.alreadyUnlocked();
      return WatchResult.success((data['energy_remaining'] as num?)?.toInt() ?? 0);
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

  Future<AdRewardResult> claimAdReward({required String rewardType}) async {
    try {
      final response = await _client.functions.invoke(
        'ad-reward',
        body: {'reward_type': rewardType},
      );
      final data = response.data as Map<String, dynamic>;
      return AdRewardResult.ok(data);
    } on FunctionException catch (e) {
      final body = e.details;
      if (e.status == 403 && body is Map && body['code'] == 'AD_CAP_REACHED') {
        return AdRewardResult.err(AdRewardError.capReached);
      }
      return AdRewardResult.err(AdRewardError.unavailable);
    } catch (_) {
      return AdRewardResult.err(AdRewardError.unavailable);
    }
  }

  Future<GemRefillResult> claimGemRefill() async {
    try {
      final response = await _client.functions.invoke('gem-refill', body: {});
      final data = response.data as Map<String, dynamic>;
      return GemRefillResult.ok(data);
    } on FunctionException catch (e) {
      final body = e.details;
      if (e.status == 402 && body is Map && body['code'] == 'INSUFFICIENT_GEMS') {
        return GemRefillResult.err(GemRefillError.insufficientGems);
      }
      if (e.status == 400 && body is Map && body['code'] == 'ENERGY_FULL') {
        return GemRefillResult.err(GemRefillError.energyFull);
      }
      return GemRefillResult.err(GemRefillError.unknown);
    } catch (_) {
      return GemRefillResult.err(GemRefillError.unknown);
    }
  }
}
