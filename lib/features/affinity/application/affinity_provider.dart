import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/affinity_repository.dart';
import '../domain/character_affinity.dart';

final affinityRepositoryProvider =
    Provider<AffinityRepository>((_) => AffinityRepository());

// H-4: lightweight bool provider to show/hide the banner without layout shift
final seriesHasCharactersProvider =
    FutureProvider.family<bool, String>((ref, seriesId) {
  return ref.read(affinityRepositoryProvider).seriesHasCharacters(seriesId);
});

// H-3 fix: ref.read instead of ref.watch inside StreamProvider body
final characterAffinitiesProvider =
    StreamProvider.family<List<CharacterAffinity>, String>((ref, seriesId) {
  return ref.read(affinityRepositoryProvider).affinityStream(seriesId);
});
