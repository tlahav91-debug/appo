import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/watch_progress_provider.dart';
import '../application/saved_dramas_provider.dart';
import '../domain/watch_progress.dart';
import '../domain/saved_drama.dart';

class MyListScreen extends ConsumerWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgDeep,
        appBar: AppBar(
          backgroundColor: bgDeep,
          elevation: 0,
          title: Text(
            'My List',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            indicatorColor: pink,
            labelColor: pink,
            unselectedLabelColor: textDim,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Continue'),
              Tab(text: 'Saved'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ContinueTab(),
            _SavedTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Continue Tab ───────────────────────────────────────────────────────────

class _ContinueTab extends ConsumerWidget {
  const _ContinueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inProgressProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: pink),
      ),
      error: (e, _) => Center(
        child: Text(
          'Failed to load. Try again.',
          style: GoogleFonts.sora(color: textDim, fontSize: 14),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No dramas in progress — start watching!',
              style: GoogleFonts.sora(color: textDim, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _ContinueCard(item: items[i]),
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final WatchProgress item;

  const _ContinueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Poster placeholder
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: cardHi,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Episode ${item.episodeId.length > 8 ? item.episodeId.substring(0, 8) : item.episodeId}…',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: item.progressPct / 100,
                  backgroundColor: cardHi,
                  valueColor: const AlwaysStoppedAnimation<Color>(pink),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.progressPct}% watched',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Jump In button
          GestureDetector(
            onTap: () => context.push('/series/${item.seriesId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: pinkFull,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Jump In',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Tab ───────────────────────────────────────────────────────────────

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedDramasProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: pink),
      ),
      error: (e, _) => Center(
        child: Text(
          'Failed to load. Try again.',
          style: GoogleFonts.sora(color: textDim, fontSize: 14),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Nothing saved yet.',
              style: GoogleFonts.sora(color: textDim, fontSize: 14),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 60 / 80,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _SavedDramaCell(drama: items[i]),
        );
      },
    );
  }
}

class _SavedDramaCell extends StatelessWidget {
  final SavedDrama drama;

  const _SavedDramaCell({required this.drama});

  @override
  Widget build(BuildContext context) {
    final label = drama.seriesId.length >= 4
        ? drama.seriesId.substring(drama.seriesId.length - 4)
        : drama.seriesId;

    return GestureDetector(
      onTap: () => context.push('/series/${drama.seriesId}'),
      child: Container(
        decoration: BoxDecoration(
          color: cardHi,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.movie_outlined, color: textDim, size: 28),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Text(
                '…$label',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: textDim, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchHistoryProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: pink),
      ),
      error: (e, _) => Center(
        child: Text(
          'Failed to load. Try again.',
          style: GoogleFonts.sora(color: textDim, fontSize: 14),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No watch history yet.',
              style: GoogleFonts.sora(color: textDim, fontSize: 14),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _HistoryRow(item: items[i]),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WatchProgress item;

  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: textDim, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Episode ${item.episodeId.length > 8 ? item.episodeId.substring(0, 8) : item.episodeId}…',
              style: GoogleFonts.sora(color: textSec, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.progressPct}%',
            style: GoogleFonts.sora(color: textDim, fontSize: 12),
          ),
          if (item.completed) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: greenDim,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.sora(color: green, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
