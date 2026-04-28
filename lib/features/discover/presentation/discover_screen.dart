import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../application/discover_provider.dart';

// Tab key used to identify the Following feed selection.
const _kFollowingTab = 'following';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';

  // '_selectedGenre' can also hold _kFollowingTab.
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

  bool get _isFollowingSelected => _selectedGenre == _kFollowingTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: _isFollowingSelected ? _buildFollowingFeed() : _buildGenreFeed(),
    );
  }

  // ── Following feed ────────────────────────────────────────────────────────

  Widget _buildFollowingFeed() {
    final followingAsync = ref.watch(followingFeedProvider);

    return RefreshIndicator(
      color: purple,
      backgroundColor: card,
      onRefresh: () async {
        ref.invalidate(followingFeedProvider);
        await ref.read(followingFeedProvider.future).catchError((_) {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildChips(),
          followingAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: purple),
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
                      'Failed to load following feed',
                      style: GoogleFonts.nunito(
                        color: textDim,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: GoogleFonts.sora(color: textDim, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (series) {
              if (series.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline,
                              color: textDim, size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'Follow creators to see their latest series here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: textSec,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: purpleGrad,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                'Discover Creators',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildListDelegate([
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
                      itemCount: series.length,
                      itemBuilder: (_, i) =>
                          _SeriesPosterCard(series: series[i]),
                    ),
                  ),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Genre feed ────────────────────────────────────────────────────────────

  Widget _buildGenreFeed() {
    final seriesAsync = ref.watch(allSeriesProvider);

    return RefreshIndicator(
      color: pink,
      backgroundColor: card,
      onRefresh: () async {
        ref.invalidate(allSeriesProvider);
        await ref.read(allSeriesProvider.future).catchError((_) {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildChips(),

          // ── Content ──────────────────────────────────────────────────
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
                      style: GoogleFonts.sora(color: textDim, fontSize: 12),
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
                  // ── Trending row ──────────────────────────────────────
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
                      padding:
                          const EdgeInsets.only(left: 16, bottom: 16),
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

                  // ── Grid ─────────────────────────────────────────────
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
    );
  }

  // ── Shared sliver widgets ─────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
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
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: textCol),
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
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
    );
  }

  Widget _buildChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // ── Following chip (always first) ──────────────────────
              _FollowingChip(
                isSelected: _isFollowingSelected,
                onTap: () =>
                    setState(() => _selectedGenre = _kFollowingTab),
              ),
              const SizedBox(width: 8),
              // ── Genre chips ────────────────────────────────────────
              ..._genres.map((genre) {
                final isSelected =
                    !_isFollowingSelected && _selectedGenre == genre;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGenre = genre),
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
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Following chip ─────────────────────────────────────────────────────────────

class _FollowingChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _FollowingChip({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? purpleGrad : null,
          color: isSelected ? null : card,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: purpleDim, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 14,
              color: isSelected ? Colors.white : purple,
            ),
            const SizedBox(width: 6),
            Text(
              'Following',
              style: GoogleFonts.nunito(
                color: isSelected ? Colors.white : purple,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count formatter ────────────────────────────────────────────────────────────

String _formatCount(int count) {
  if (count >= 1000) {
    final k = count / 1000;
    // Show one decimal place only when needed (e.g. 1.2k, not 1.0k)
    return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  return '$count';
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
                      color: bgDeep,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            // Trending badge — top right, below VIP badge when both present
            if (series.viewCount7d >= 100)
              Positioned(
                top: series.isVip ? 30 : 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: purpleDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🔥 ${_formatCount(series.viewCount7d)}',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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
