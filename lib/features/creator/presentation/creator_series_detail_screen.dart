import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_series_provider.dart';

class CreatorSeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;
  const CreatorSeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<CreatorSeriesDetailScreen> createState() =>
      _CreatorSeriesDetailScreenState();
}

class _CreatorSeriesDetailScreenState
    extends ConsumerState<CreatorSeriesDetailScreen> {
  Map<String, dynamic>? _series;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = await ref
          .read(creatorSeriesRepositoryProvider)
          .fetchSeriesById(widget.seriesId);
      if (mounted) setState(() => _series = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync =
        ref.watch(seriesSubmissionsProvider(widget.seriesId));
    final title = _series?['title'] as String? ?? '';
    final description = _series?['description'] as String? ?? '';
    final coverUrl = _series?['cover_url'] as String?;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          title.isNotEmpty ? title : 'Series',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: textDim),
            onPressed: () =>
                context.push('/creator/series/${widget.seriesId}/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: gold,
        onRefresh: () async {
          ref.invalidate(seriesSubmissionsProvider(widget.seriesId));
          final s = await ref
              .read(creatorSeriesRepositoryProvider)
              .fetchSeriesById(widget.seriesId);
          if (mounted) setState(() => _series = s);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover image
            if (coverUrl != null && coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  coverUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.movie_outlined, color: textDim, size: 40),
                ),
              ),

            const SizedBox(height: 16),

            if (description.isNotEmpty) ...[
              Text(description,
                  style: GoogleFonts.sora(color: textSec, fontSize: 13)),
              const SizedBox(height: 16),
            ],

            Text('Episodes',
                style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 8),

            submissionsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: gold, strokeWidth: 2)),
              error: (_, __) => Text('Failed to load episodes',
                  style: GoogleFonts.sora(color: textDim, fontSize: 13)),
              data: (subs) {
                if (subs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No episodes yet.',
                        style: GoogleFonts.sora(
                            color: textDim, fontSize: 13)),
                  );
                }
                return Column(
                  children: subs.map((sub) {
                    final epNum = sub['episode_number'] as int? ?? 0;
                    final epTitle = sub['title'] as String? ?? '';
                    final status = sub['status'] as String? ?? 'draft';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'E$epNum',
                              style: GoogleFonts.sora(
                                  color: textCol,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(epTitle,
                                    style: GoogleFonts.sora(
                                        color: textCol, fontSize: 13)),
                                const SizedBox(height: 4),
                                _StatusBadge(status: status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => context.push(
                  '/creator/series/${widget.seriesId}/episode/new'),
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: pinkGrad,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Add Episode',
                  style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, grad, useBorder) = switch (status) {
      'submitted' => ('Under Review', purpleGrad, false),
      'approved' => ('Live ✓', greenGrad, false),
      'rejected' => ('Rejected', pinkGrad, false),
      _ => ('Draft', null, true),
    };

    if (useBorder) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: borderHi),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.sora(color: textDim, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.sora(
              color: textCol, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
