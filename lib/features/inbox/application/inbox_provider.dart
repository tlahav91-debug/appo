import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inbox_service.dart';
import '../domain/inbox_item.dart';

final inboxServiceProvider = Provider<InboxService>((ref) => InboxService());

final inboxItemsProvider = FutureProvider<List<InboxItem>>((ref) =>
  ref.read(inboxServiceProvider).fetchItems());

final unreadCountProvider = Provider<int>((ref) {
  final items = ref.watch(inboxItemsProvider).valueOrNull ?? [];
  return items.where((i) => !i.claimed && !i.isExpired).length;
});
