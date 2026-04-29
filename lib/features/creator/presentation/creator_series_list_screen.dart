import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_series_provider.dart';

class CreatorSeriesListScreen extends ConsumerWidget {
  const CreatorSeriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(mySeriesProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'My Series',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        onPressed: () => context.push('/creator/series/new'),
        child: const Icon(Icons.add, color: bgDeep),
      ),
      body: seriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: gold)),
        error: (_, __) => Center(
          child: Text('Failed to load series',
              style: GoogleFonts.sora(color: textDim)),
        ),
        data: (seriesList) {
          if (seriesList.isEmpty) {
            return Center(
              child: Text(
                'No series yet. Tap + to create one.',
                style: GoogleFonts.sora(color: textDim, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: seriesList.length,
            itemBuilder: (context, i) {
              final s = seriesList[i];
              final coverUrl = s['cover_url'] as String?;
              final title = s['title'] as String? ?? '';
              final genre = s['genre'] as String? ?? '';
              return GestureDetector(
                onTap: () =>
                    context.push('/creator/series/${s['id']}'),
                onLongPress: () => _confirmDelete(context, ref, s['id'] as String, title),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: card,
                        backgroundImage: coverUrl != null && coverUrl.isNotEmpty
                            ? NetworkImage(coverUrl)
                            : null,
                        child: coverUrl == null || coverUrl.isEmpty
                            ? Text(
                                title.isNotEmpty
                                    ? title[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.nunito(
                                    color: textCol,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: GoogleFonts.nunito(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            if (genre.isNotEmpty)
                              Text(genre,
                                  style: GoogleFonts.sora(
                                      color: textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: textDim, size: 18),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Delete Series?',
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w800)),
        content: Text('Delete "$title" and all its episodes?',
            style: GoogleFonts.sora(color: textSec, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.sora(color: textDim)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(creatorSeriesRepositoryProvider)
                  .deleteSeries(id);
              ref.invalidate(mySeriesProvider);
            },
            child: Text('Delete',
                style: GoogleFonts.sora(color: lava)),
          ),
        ],
      ),
    );
  }
}
