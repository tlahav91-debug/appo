import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorSeriesRepository {
  final _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMySeries() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _db
        .from('series')
        .select('id, title, description, genre, cover_url, created_at')
        .eq('creator_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<String> createSeries({
    required String title,
    String description = '',
    String genre = '',
    String? coverUrl,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final row = await _db
        .from('series')
        .insert({
          'creator_id': uid,
          'title': title,
          'description': description,
          'genre': genre,
          if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl,
          'is_vip': false,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateSeries(
    String id, {
    String? title,
    String? description,
    String? genre,
    String? coverUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (genre != null) updates['genre'] = genre;
    if (coverUrl != null) updates['cover_url'] = coverUrl;
    if (updates.isEmpty) return;
    await _db.from('series').update(updates).eq('id', id);
  }

  Future<void> deleteSeries(String id) async {
    await _db.from('series').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> fetchSeriesById(String id) async {
    final data = await _db
        .from('series')
        .select('id, title, description, genre, cover_url')
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> fetchSubmissionsForSeries(
      String seriesId) async {
    final data = await _db
        .from('content_submissions')
        .select(
            'id, title, episode_number, status, thumbnail_url, cf_stream_id, rejection_reason, created_at')
        .eq('series_id', seriesId)
        .order('episode_number', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // Calls get-upload-url Edge Fn (creates CF Stream slot + draft submission),
  // then links the new submission to the series. Returns {uploadUrl, submissionId}.
  Future<({String uploadUrl, String submissionId})> requestUploadSlot({
    required String seriesId,
    required String title,
    required int episodeNumber,
    required int fileSizeMb,
    String genre = '',
  }) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');

    final res = await _db.functions.invoke(
      'get-upload-url',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'title': title,
        'episode_number': episodeNumber,
        'file_size': fileSizeMb * 1024 * 1024,
        if (genre.isNotEmpty) 'genre': genre,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final submissionId = data['submission_id'] as String;
    final uploadUrl = data['upload_url'] as String;

    // Link submission to this series (submissions_update_own_draft policy allows this).
    // On failure: clean up the orphaned draft so it doesn't accumulate junk rows.
    try {
      await _db
          .from('content_submissions')
          .update({'series_id': seriesId})
          .eq('id', submissionId)
          .eq('status', 'draft');
    } catch (_) {
      await _db
          .from('content_submissions')
          .delete()
          .eq('id', submissionId)
          .eq('status', 'draft');
      rethrow;
    }

    return (uploadUrl: uploadUrl, submissionId: submissionId);
  }

  Future<void> submitForReview(String submissionId) async {
    final session = _db.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    await _db.functions.invoke(
      'submit-content',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'submission_id': submissionId},
    );
  }
}
