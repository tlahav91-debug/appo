import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/episode_comment.dart';

final commentsProvider =
    FutureProvider.family<List<EpisodeComment>, String>((ref, episodeId) async {
  final data = await Supabase.instance.client
      .from('episode_comments')
      .select('*, profiles(username, avatar_url)')
      .eq('episode_id', episodeId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((e) => EpisodeComment.fromJson(e as Map<String, dynamic>))
      .toList();
});

final commentCountProvider =
    FutureProvider.family<int, String>((ref, episodeId) async {
  final data = await Supabase.instance.client
      .from('episode_comments')
      .select('id')
      .eq('episode_id', episodeId)
      .isFilter('deleted_at', null);
  return (data as List).length;
});
