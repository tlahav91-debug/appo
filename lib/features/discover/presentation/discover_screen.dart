import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../application/discover_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  String _selectedGenre = 'All';

  static const _genres = [
    'All',
    'Romance',
    'Thriller',
    'Comedy',
    'Drama',
    'Action',
    'Mystery',
  ];

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(allSeriesProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      body: RefreshIndicator(
        color: pink,
        backgroundColor: card,
        onRefresh: () async {
          ref.invalidate(allSeriesProvider);
          // Wait for the new data to load
          await ref.read(allSeriesProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: bg,
              elevation: 0,
              title: Text(
                'Discover',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  style: GoogleFonts.sora(color: textCol, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: textDim),
                    hintText: 'Search dramas…',
                    hintStyle: GoogleFonts.sora(color: textDim, fontSize: 14),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ),

            // ── Genre chips ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _genres.map((genre) {
                      final isSelected = _selectedGenre == genre;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedGenre = genre),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? pinkFull : null,
                            color: isSelected ? null : card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            genre,
                            style: GoogleFonts.nunito(
                              color: isSelected ? Colors.white : textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            seriesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: pink),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: lava, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load dramas',
                        style: GoogleFonts.nunito(
                          color: textDim,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style:
                            GoogleFonts.sora(color: textDim, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (series) {
                final filtered = series.where((s) {
                  final matchesQuery = _query.isEmpty ||
                      s.title.toLowerCase().contains(_query);
                  final matchesGenre = _selectedGenre == 'All' ||
                      (s.genre?.toLowerCase() ==
                          _selectedGenre.toLowerCase());
                  return matchesQuery && matchesGenre;
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off,
                              color: textDim, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No dramas found',
                            style: GoogleFonts.nunito(
                              color: textDim,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final showTrending =
                    _query.isEmpty && _selectedGenre == 'All';

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Trending row ────────────────────────────────────────
                    if (showTrending) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Text(
                          '🔥 Trending Now',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: filtered
                                .take(10)
                                .map((s) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10),
                                      child: _SeriesPosterCard(
                                        series: s,
                                        width: 100,
                                        height: 140,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],

                    // ── Grid ────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _SeriesPosterCard(series: filtered[i]),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private poster card ────────────────────────────────────────────────────────

class _SeriesPosterCard extends StatelessWidget {
  final DiscoverSeries series;
  final double width;
  final double height;

  const _SeriesPosterCard({
    required this.series,
    this.width = 100,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/${series.id}'),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          image: series.coverUrl != null
              ? DecorationImage(
                  image: NetworkImage(series.coverUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
              ),
            ),
            // Title
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Text(
                series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // VIP badge
            if (series.isVip)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: goldGrad,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VIP',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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
