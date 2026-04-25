import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/affinity_repository.dart';
import '../domain/character_affinity.dart';

final affinityRepositoryProvider =
    Provider<AffinityRepository>((_) => AffinityRepository());

final characterAffinitiesProvider =
    StreamProvider.family<List<CharacterAffinity>, String>((ref, seriesId) {
  return ref.watch(affinityRepositoryProvider).affinityStream(seriesId);
});
