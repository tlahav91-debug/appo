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
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 80,
              child: item.coverUrl != null
                  ? Image(
                      image: NetworkImage(item.coverUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: card,
                        child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
                      ),
                    )
                  : Container(
                      color: card,
                      child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.seriesTitle ?? 'Drama',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ep ${item.episodeNumber ?? ''}: ${item.episodeTitle ?? ''}',
                  style: GoogleFonts.sora(color: textSec, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: item.progressPct / 100,
                  backgroundColor: border,
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
    return GestureDetector(
      onTap: () => context.push('/series/${drama.seriesId}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster or fallback
            drama.coverUrl != null
                ? Image(
                    image: NetworkImage(drama.coverUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cardHi,
                      child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
                    ),
                  )
                : Container(
                    color: cardHi,
                    child: const Icon(Icons.movie_outlined, color: textDim, size: 28),
                  ),
            // Title overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      bgDeep.withValues(alpha: 0.9),
                      bgDeep.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Text(
                  drama.title ?? 'Drama',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            // VIP badge
            if (drama.isVip)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: goldGrad,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'VIP',
                    style: GoogleFonts.nunito(
                      color: bgDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.seriesTitle ?? 'Drama',
                  style: GoogleFonts.sora(color: textCol, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Ep ${item.episodeNumber ?? ''}: ${item.episodeTitle ?? ''}',
                  style: GoogleFonts.sora(color: textSec, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
