import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/album_repository.dart';
import '../domain/album.dart';
import '../domain/collectible.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository(Supabase.instance.client);
});

final albumProvider = FutureProvider.family<Album?, String>(
  (ref, seriesId) => ref.read(albumRepositoryProvider).fetchAlbumForSeries(seriesId),
);

final seriesCollectiblesProvider = FutureProvider.family<List<Collectible>, String>(
  (ref, seriesId) =>
      ref.read(albumRepositoryProvider).fetchCollectiblesForSeries(seriesId),
);

final ownedCollectibleIdsProvider = FutureProvider<Set<String>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Future.value({});
  return ref.read(albumRepositoryProvider).fetchOwnedCollectibleIds(userId);
});
