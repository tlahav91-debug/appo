import 'package:supabase_flutter/supabase_flutter.dart';

class CollectibleService {
  final _client = Supabase.instance.client;

  Future<({String collectibleId, bool alreadyOwned})> mintForEpisode(String episodeId) async {
    final res = await _client.functions.invoke(
      'mint-collectible',
      body: {'episode_id': episodeId},
    );
    final data = res.data as Map<String, dynamic>;
    return (
      collectibleId: data['collectible_id'] as String,
      alreadyOwned: data['already_owned'] as bool? ?? false,
    );
  }
}
