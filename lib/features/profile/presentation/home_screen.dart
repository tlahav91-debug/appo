import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../../../features/achievements/application/achievements_provider.dart';
import '../../../features/daily_reward/presentation/daily_reward_banner.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/stars.dart';
import '../../club/application/club_provider.dart';
import '../../club/domain/watch_club.dart';
import '../../events/application/lava_quest_provider.dart';
import '../../mylist/application/watch_progress_provider.dart';
import '../../mylist/domain/watch_progress.dart';
import '../application/home_provider.dart';
import '../application/profile_provider.dart';
import '../../qa/application/qa_provider.dart';
import '../../qa/domain/qa_session.dart';

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
  String? _selectedGenre;

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
    ref.invalidate(trendingSeriesProvider);
    ref.invalidate(inProgressProvider);
    ref.invalidate(userClubProvider);
    ref.invalidate(activeQuestsProvider);
    ref.invalidate(newFromFollowingProvider);
    ref.invalidate(creatorSpotlightProvider);
    ref.invalidate(seriesCompletionsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredSeriesProvider);
    final allSeriesAsync = ref.watch(allSeriesForGridProvider);
    final trendingAsync = ref.watch(trendingSeriesProvider);
    final inProgressAsync = ref.watch(inProgressProvider);
    final clubAsync = ref.watch(userClubProvider);
    final activeQuestsAsync = ref.watch(activeQuestsProvider);
    final upcomingQA = ref.watch(upcomingQAProvider).valueOrNull;
    final followingEpisodes = ref.watch(newFromFollowingProvider).valueOrNull ?? [];
    final spotlight = ref.watch(creatorSpotlightProvider).valueOrNull;

    // Derive a single active quest (first in the list), if any.
    final activeQuest = activeQuestsAsync.valueOrNull?.firstOrNull;

    // Derive distinct genres from loaded series for the filter chips.
    final allGenres = (allSeriesAsync.valueOrNull ?? [])
        .map((s) => s.genre)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

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
                // 2b. Daily Reward Banner
                // ----------------------------------------------------------------
                const SliverToBoxAdapter(child: DailyRewardBanner()),

                // ----------------------------------------------------------------
                // 3. Continue Watching Strip
                // ----------------------------------------------------------------
                ..._buildContinueWatching(inProgressAsync),

                // ----------------------------------------------------------------
                // 3b. New from Following Strip
                // ----------------------------------------------------------------
                if (followingEpisodes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FollowingStrip(episodes: followingEpisodes),
                  ),

                // ----------------------------------------------------------------
                // 4. Club Activity Strip
                // ----------------------------------------------------------------
                ..._buildClubStrip(clubAsync),

                // ----------------------------------------------------------------
                // 4b. Upcoming Q&A Banner
                // ----------------------------------------------------------------
                if (upcomingQA != null)
                  SliverToBoxAdapter(
                    child: _QABanner(session: upcomingQA),
                  ),

                // ----------------------------------------------------------------
                // 4c. Trending Now Row
                // ----------------------------------------------------------------
                _TrendingRow(trendingAsync: trendingAsync),

                // ----------------------------------------------------------------
                // 4d. Creator Spotlight
                // ----------------------------------------------------------------
                if (spotlight != null)
                  SliverToBoxAdapter(
                    child: _CreatorSpotlightCard(spotlight: spotlight),
                  ),

                // ----------------------------------------------------------------
                // 5. "All Dramas" header + Genre filter chips
                // ----------------------------------------------------------------
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            Text(
                              'All Dramas',
                              style: GoogleFonts.nunito(
                                color: textCol,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedGenre != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedGenre = null),
                                child: Text(
                                  'Clear',
                                  style: GoogleFonts.sora(
                                      color: pink, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (allGenres.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: allGenres.length,
                            itemBuilder: (context, i) {
                              final genre = allGenres[i];
                              final selected = _selectedGenre == genre;
                              return GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedGenre = selected ? null : genre),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: selected ? pinkFull : null,
                                    color: selected ? null : surface,
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  child: Text(
                                    genre,
                                    style: GoogleFonts.sora(
                                      color:
                                          selected ? textCol : textSec,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ----------------------------------------------------------------
                // 5b. Drama Grid (filtered by genre chip when selected)
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
                    var displayed = List<HomeSeries>.from(series);
                    if (_selectedGenre != null) {
                      displayed = displayed
                          .where((s) => s.genre == _selectedGenre)
                          .toList();
                    } else {
                      final prefs = ref
                              .watch(profileProvider)
                              .valueOrNull
                              ?.genrePreferences ??
                          [];
                      if (prefs.isNotEmpty) {
                        displayed.sort((a, b) {
                          final aMatch = prefs.contains(a.genre) ? 0 : 1;
                          final bMatch = prefs.contains(b.genre) ? 0 : 1;
                          return aMatch.compareTo(bMatch);
                        });
                      }
                    }
                    if (displayed.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No dramas in this genre yet.',
                              style: GoogleFonts.sora(
                                  color: textDim, fontSize: 13),
                            ),
                          ),
                        ),
                      );
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
                              _GridSeriesCard(series: displayed[index]),
                          childCount: displayed.length,
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
    return GestureDetector(
      onTap: () => context.push('/series/${wp.seriesId}'),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (wp.coverUrl != null && wp.coverUrl!.isNotEmpty)
                Image.network(
                  wp.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: purpleGrad),
                  ),
                )
              else
                Container(decoration: const BoxDecoration(gradient: purpleGrad)),
              if (wp.seriesTitle != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      wp.seriesTitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: wp.progressPct / 100,
                  color: pink,
                  backgroundColor: Colors.black38,
                  minHeight: 3,
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
// Trending Now Row
// ---------------------------------------------------------------------------

class _TrendingRow extends StatelessWidget {
  final AsyncValue<List<HomeSeries>> trendingAsync;

  const _TrendingRow({required this.trendingAsync});

  @override
  Widget build(BuildContext context) {
    return trendingAsync.when(
      loading: () => SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: List.generate(
              3,
              (_) => Container(
                width: 80,
                height: 120,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, __) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (series) {
        if (series.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '🔥 Trending',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: series.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _TrendingPosterCard(
                      series: series[index],
                      rank: index + 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trending Poster Card
// ---------------------------------------------------------------------------

class _TrendingPosterCard extends StatelessWidget {
  final HomeSeries series;
  final int rank;

  const _TrendingPosterCard({
    required this.series,
    required this.rank,
  });

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: purpleGrad,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/${series.id}'),
      child: SizedBox(
        width: 90,
        height: 130,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image or placeholder
              if (series.coverUrl != null && series.coverUrl!.isNotEmpty)
                Image.network(
                  series.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),

              // Rank badge — top left
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: purpleGrad,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
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
// Drama Grid Series Card
// ---------------------------------------------------------------------------

class _GridSeriesCard extends ConsumerWidget {
  final HomeSeries series;

  const _GridSeriesCard({required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(seriesCompletionsProvider).valueOrNull ?? const {};
    final isCompleted = completedIds.contains(series.id);

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

              // Completion checkmark — top left
              if (isCompleted)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: goldGrad,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: bgDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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
// New from Following Strip
// ---------------------------------------------------------------------------

class _FollowingStrip extends StatelessWidget {
  final List<FollowingEpisode> episodes;
  const _FollowingStrip({required this.episodes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '✨ New from Following',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Text(
                  'See All',
                  style: GoogleFonts.sora(color: pink, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: episodes.length,
            itemBuilder: (context, index) =>
                _FollowingCard(episode: episodes[index]),
          ),
        ),
      ],
    );
  }
}

class _FollowingCard extends StatelessWidget {
  final FollowingEpisode episode;
  const _FollowingCard({required this.episode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/${episode.seriesId}'),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (episode.coverUrl != null && episode.coverUrl!.isNotEmpty)
                Image.network(
                  episode.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: purpleGrad),
                  ),
                )
              else
                Container(decoration: const BoxDecoration(gradient: purpleGrad)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 70,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      episode.seriesTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(color: textSec, fontSize: 10),
                    ),
                    Text(
                      'Ep ${episode.episodeNumber}',
                      maxLines: 1,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'by ${episode.creatorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(color: pink, fontSize: 10),
                    ),
                  ],
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
// Creator Spotlight Card
// ---------------------------------------------------------------------------

class _CreatorSpotlightCard extends StatelessWidget {
  final CreatorSpotlight spotlight;
  const _CreatorSpotlightCard({required this.spotlight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/creator/${spotlight.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: purple,
                  backgroundImage: spotlight.avatarUrl != null &&
                          spotlight.avatarUrl!.isNotEmpty
                      ? NetworkImage(spotlight.avatarUrl!)
                      : null,
                  child: spotlight.avatarUrl == null ||
                          spotlight.avatarUrl!.isEmpty
                      ? Text(
                          spotlight.displayName.isNotEmpty
                              ? spotlight.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⭐ Creator Spotlight',
                        style: GoogleFonts.sora(color: gold, fontSize: 11),
                      ),
                      Text(
                        spotlight.displayName,
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${spotlight.followerCount} followers · '
                        '${spotlight.seriesCount} series',
                        style: GoogleFonts.sora(color: textSec, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: textDim, size: 20),
              ],
            ),
            if (spotlight.bio != null && spotlight.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                spotlight.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(color: textSec, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QABanner extends StatelessWidget {
  final QASession session;
  const _QABanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final isLive = session.status == QAStatus.live;
    final timeStr = isLive
        ? 'LIVE NOW 🔴'
        : '${session.scheduledAt.hour.toString().padLeft(2, '0')}:'
            '${session.scheduledAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => context.push('/qa/session/${session.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: purpleGrad,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🎤', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isLive ? 'Live Q&A — join now!' : 'Upcoming Q&A · $timeStr',
                    style: GoogleFonts.sora(
                        color: textCol.withAlpha(200), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textCol),
          ],
        ),
      ),
    );
  }
}
