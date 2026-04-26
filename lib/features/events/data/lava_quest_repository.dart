import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lava_quest.dart';

class LavaQuestRepository {
  final _db = Supabase.instance.client;

  Future<List<LavaQuest>> fetchActiveQuests() async {
    final userId = _db.auth.currentUser?.id;
    final now = DateTime.now().toUtc().toIso8601String();

    final quests = await _db
        .from('lava_quests')
        .select()
        .eq('is_active', true)
        .lte('starts_at', now)
        .gt('ends_at', now)
        .order('ends_at');

    if (quests.isEmpty) return [];

    final questIds = quests.map((q) => q['id'] as String).toList();

    // Fetch this user's progress for these quests
    Map<String, Map<String, dynamic>> progressMap = {};
    if (userId != null) {
      final progressRows = await _db
          .from('user_quest_progress')
          .select('quest_id, progress, completed_at, reward_claimed_at')
          .eq('user_id', userId)
          .inFilter('quest_id', questIds);
      for (final row in progressRows) {
        progressMap[row['quest_id'] as String] = row;
      }
    }

    return quests.map((q) {
      final prog = progressMap[q['id'] as String];
      return LavaQuest.fromJson({
        ...q,
        'progress': prog?['progress'] ?? 0,
        'completed_at': prog?['completed_at'],
        'reward_claimed_at': prog?['reward_claimed_at'],
      });
    }).toList();
  }

  Future<LavaQuest?> fetchQuestById(String questId) async {
    final userId = _db.auth.currentUser?.id;

    final data = await _db
        .from('lava_quests')
        .select()
        .eq('id', questId)
        .maybeSingle();

    if (data == null) return null;

    Map<String, dynamic>? prog;
    if (userId != null) {
      prog = await _db
          .from('user_quest_progress')
          .select('progress, completed_at, reward_claimed_at')
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .maybeSingle();
    }

    return LavaQuest.fromJson({
      ...data,
      'progress': prog?['progress'] ?? 0,
      'completed_at': prog?['completed_at'],
      'reward_claimed_at': prog?['reward_claimed_at'],
    });
  }

  Stream<List<LavaQuest>> activeQuestsStream() async* {
    yield await fetchActiveQuests();

    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    final ctrl = StreamController<void>.broadcast();
    final channel = _db.channel('quest_progress_$userId');

    try {
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_quest_progress',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (_) => ctrl.add(null),
          )
          .subscribe();

      await for (final _ in ctrl.stream) {
        yield await fetchActiveQuests();
      }
    } finally {
      await ctrl.close();
      _db.removeChannel(channel);
    }
  }

  Future<Map<String, dynamic>> claimReward(String questId) async {
    final res = await _db.functions.invoke(
      'claim-quest-reward',
      body: {'quest_id': questId},
    );
    if (res.status != 200) {
      throw Exception('Failed to claim reward (${res.status}): ${res.data}');
    }
    final data = res.data as Map<String, dynamic>;
    return {
      'gems_earned':   (data['gems_earned'] as num).toInt(),
      'coins_earned':  (data['coins_earned'] as num).toInt(),
      'xp_gained':     (data['xp_gained'] as num?)?.toInt() ?? 0,
      'leveled_up':    data['leveled_up'] == true,
      'new_fan_level': (data['new_fan_level'] as num?)?.toInt(),
      'idempotent':    data['idempotent'] == true,
    };
  }
}
