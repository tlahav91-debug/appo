import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meta_service.dart';
import '../domain/meta_item.dart';

final metaServiceProvider = Provider<MetaService>((ref) => MetaService());

final metaUnlockedIdsProvider = FutureProvider<Set<String>>((ref) =>
    ref.read(metaServiceProvider).fetchUnlockedIds());

final metaLoadoutProvider = FutureProvider<MetaLoadout>((ref) =>
    ref.read(metaServiceProvider).fetchLoadout());
