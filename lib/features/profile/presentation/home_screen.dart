import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/stars.dart';
import '../../club/application/club_provider.dart';
import '../../club/domain/watch_club.dart';
import '../../events/application/lava_quest_provider.dart';
import '../../mylist/application/watch_progress_provider.dart';
import '../../mylist/domain/watch_progress.dart';
import '../application/home_provider.dart';
import '../application/profile_provider.dart';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  Timer? _timer;
  // Updated when featuredSeriesProvider data arrives; guards timer from
  // animating to out-of-bounds page when fewer than 5 series are returned.
  int _featuredCount = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients && _featuredCount > 1) {
        final next = (_pageController.page?.round() ?? 0) + 1;
        _pageController.animateToPage(
          next % _featuredCount,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(featuredSeriesProvider);
    ref.invalidate(allSeriesForGridProvider);
    ref.invalidate(inProgressProvider);
    ref.invalidate(userClubProvider);
    ref.invalidate(activeQuestsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredSeriesProvider);
    final allSeriesAsync = ref.watch(allSeriesForGridProvider);
    final inProgressAsync = ref.watch(inProgressProvider);
    final clubAsync = ref.watch(userClubProvider);
    final activeQuestsAsync = ref.watch(activeQuestsProvider);

    // Derive a single active quest (first in the list), if any.
    final activeQuest = activeQuestsAsync.valueOrNull?.firstOrNull;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          RefreshIndicator(
            color: pink,
            backgroundColor: card,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ----------------------------------------------------------------
                // 1. Hero Carousel
                // ----------------------------------------------------------------
                SliverToBoxAdapter(
                  child: featuredAsync.when(
                    loading: () => const _HeroCarouselSkeleton(),
                    error: (_, __) => const _HeroCarouselSkeleton(),
                    data: (series) {
                      _featuredCount = series.isEmpty ? 1 : series.length;
                      return _HeroCarousel(
                        seriesList: series,
                        pageController: _pageController,
                      );
                    },
                  ),
                ),

                // ----------------------------------------------------------------
                // 2. Quick Links Row
                // ----------------------------------------------------------------
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Events card
                          _QuickLinkCard(
                            icon: '⚡',
                            label: 'Live Events',
                            gradient: const LinearGradient(
                              colors: [bgDeep, pink],
                            ),
                            onTap: () => context.push('/events'),
                          ),
                          const SizedBox(width: 12),
                          _QuickLinkCard(
                            icon: '🗺️',
                            label: 'Journey',
                            gradient: const LinearGradient(
                              colors: [bgDeep, cyan],
                            ),
                            onTap: () => context.push('/journey'),
                          ),
                          // Active quest card — only when there's an active quest
                          if (activeQuest != null) ...[
                            const SizedBox(width: 12),
                            _QuickLinkCard(
                              icon: '🔥',
                              label: 'Lava Quest',
                              gradient: lavaGrad,
                              onTap: () =>
                                  context.push('/quest/${activeQuest.id}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // 3. Continue Watching Strip
                // ----------------------------------------------------------------
                ..._buildContinueWatching(inProgressAsync),

                // ----------------------------------------------------------------
                // 4. Club Activity Strip
                // ----------------------------------------------------------------
                ..._buildClubStrip(clubAsync),

                // ----------------------------------------------------------------
                // 5. "All Dramas" section header
                // ----------------------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'All Dramas',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // 5b. Drama Grid
                // ----------------------------------------------------------------
                allSeriesAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: pink,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Failed to load dramas',
                          style: TextStyle(color: textSec),
                        ),
                      ),
                    ),
                  ),
                  data: (series) {
                    final prefs = ref
                            .watch(profileProvider)
                            .valueOrNull
                            ?.genrePreferences ??
                        [];
                    if (prefs.isNotEmpty) {
                      series = List<HomeSeries>.from(series);
                      series.sort((a, b) {
                        final aMatch =
                            prefs.contains(a.genre) ? 0 : 1;
                        final bMatch =
                            prefs.contains(b.genre) ? 0 : 1;
                        return aMatch.compareTo(bMatch);
                      });
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _GridSeriesCard(series: series[index]),
                          childCount: series.length,
                        ),
                      ),
                    );
                  },
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Continue Watching slivers
  // ---------------------------------------------------------------------------
  List<Widget> _buildContinueWatching(
      AsyncValue<List<WatchProgress>> inProgressAsync) {
    final items = inProgressAsync.valueOrNull;
    if (items == null || items.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Continue Watching',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final wp = items[index];
              return _ContinueCard(wp: wp);
            },
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Club Strip sliver
  // ---------------------------------------------------------------------------
  List<Widget> _buildClubStrip(AsyncValue<WatchClub?> clubAsync) {
    if (!clubAsync.hasValue) return [];
    final club = clubAsync.value;
    if (club == null) return [];

    return [
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                club.name,
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '🔥 Active',
                style: GoogleFonts.sora(color: pink, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Hero Carousel
// ---------------------------------------------------------------------------

class _HeroCarousel extends StatefulWidget {
  final List<HomeSeries> seriesList;
  final PageController pageController;

  const _HeroCarousel({
    required this.seriesList,
    required this.pageController,
  });

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page % widget.seriesList.length);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.seriesList.isEmpty) return const _HeroCarouselSkeleton();

    final count = widget.seriesList.length;

    return Container(
      height: 280,
      color: Colors.transparent,
      child: Column(
        children: [
          // PageView
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: count,
              itemBuilder: (context, index) =>
                  _HeroCard(series: widget.seriesList[index % count]),
            ),
          ),
          // Page indicator dots
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count > 8 ? 8 : count, (i) {
              final active = (i == _currentPage % count);
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? pink
                      : textDim.withOpacity(0.5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeroCarouselSkeleton extends StatelessWidget {
  const _HeroCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: pink, strokeWidth: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Card
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  final HomeSeries series;

  const _HeroCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [card, surface]),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              if (series.coverUrl != null && series.coverUrl!.isNotEmpty)
                Image.network(
                  series.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

              // Bottom gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.87),
                      ],
                    ),
                  ),
                ),
              ),

              // VIP badge — top right
              if (series.isVip)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: goldGrad,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VIP',
                      style: GoogleFonts.nunito(
                        color: bgDeep,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

              // Bottom-left: title + episodes
              Positioned(
                left: 12,
                right: 100,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (series.totalEpisodes > 0)
                      Text(
                        '${series.totalEpisodes} Episodes',
                        style: GoogleFonts.sora(
                          color: textSec,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom-right: Watch Now button
              Positioned(
                right: 12,
                bottom: 14,
                child: GestureDetector(
                  onTap: () => context.push('/series/${series.id}'),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: pinkFull,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Watch Now',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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
}

// ---------------------------------------------------------------------------
// Quick Link Card
// ---------------------------------------------------------------------------

class _QuickLinkCard extends StatelessWidget {
  final String icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 80,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Continue Watching Card
// ---------------------------------------------------------------------------

class _ContinueCard extends StatelessWidget {
  final WatchProgress wp;

  const _ContinueCard({required this.wp});

  @override
  Widget build(BuildContext context) {
    final shortId = wp.seriesId.length >= 8
        ? wp.seriesId.substring(wp.seriesId.length - 8)
        : wp.seriesId;

    return GestureDetector(
      onTap: () => context.push('/series/${wp.seriesId}'),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  shortId,
                  style: GoogleFonts.sora(
                    color: textDim,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: LinearProgressIndicator(
                value: wp.progressPct / 100,
                color: pink,
                backgroundColor: border,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drama Grid Series Card
// ---------------------------------------------------------------------------

class _GridSeriesCard extends StatelessWidget {
  final HomeSeries series;

  const _GridSeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/${series.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              if (series.coverUrl != null && series.coverUrl!.isNotEmpty)
                Image.network(
                  series.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: card),
                ),

              // Bottom title overlay gradient
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.80),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(6, 16, 6, 6),
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
                ),
              ),

              // VIP badge — top right
              if (series.isVip)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: goldGrad,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VIP',
                      style: GoogleFonts.nunito(
                        color: bgDeep,
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
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
}
