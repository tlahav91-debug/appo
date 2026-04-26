import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeriesRatingState {
  final double avgRating;   // 0.0 if no ratings
  final int ratingCount;
  final int? myRating;      // null if not rated

  const SeriesRatingState({
    required this.avgRating,
    required this.ratingCount,
    this.myRating,
  });
}

final seriesRatingProvider = FutureProvider.family<SeriesRatingState, String>(
  (ref, seriesId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final data = await Supabase.instance.client
        .from('series_ratings')
        .select('rating, user_id')
        .eq('series_id', seriesId);

    final rows = (data as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const SeriesRatingState(avgRating: 0, ratingCount: 0);

    final total = rows.fold<int>(0, (sum, r) => sum + (r['rating'] as num).toInt());
    final avg = total / rows.length;
    final myRating = userId != null
        ? (rows.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r!['user_id'] == userId,
            orElse: () => null,
          )?['rating'] as num?)?.toInt()
        : null;

    return SeriesRatingState(
      avgRating: avg,
      ratingCount: rows.length,
      myRating: myRating,
    );
  },
);

class RatingService {
  Future<void> submitRating(String seriesId, int rating) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('series_ratings').upsert({
      'user_id': userId,
      'series_id': seriesId,
      'rating': rating,
    }, onConflict: 'user_id,series_id');
  }
}

final ratingServiceProvider = Provider((ref) => RatingService());
