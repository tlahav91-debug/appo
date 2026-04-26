import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/saved_drama_service.dart';
import '../domain/saved_drama.dart';

final savedDramaServiceProvider = Provider<SavedDramaService>((ref) => SavedDramaService());

final savedDramasProvider = FutureProvider<List<SavedDrama>>((ref) async {
  final rows = await ref.read(savedDramaServiceProvider).fetchSaved();
  return rows.map(SavedDrama.fromJson).toList();
});
