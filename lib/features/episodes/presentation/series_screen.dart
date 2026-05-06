import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/share_utils.dart';
import '../../../shared/widgets/g_btn.dart';
import '../../../shared/widgets/hud.dart';
import '../../energy/presentation/energy_gate.dart';
import '../../energy/application/energy_provider.dart';
import '../application/episodes_provider.dart';
import '../application/series_detail_provider.dart';
import '../domain/episode.dart';
import '../../energy/domain/watch_result.dart';
import '../../affinity/application/affinity_provider.dart'
    show seriesHasCharactersProvider;
import '../../events/presentation/marathon_banner.dart';
import '../../race/application/race_provider.dart';
import '../../race/domain/race.dart';
import '../../creator/application/creator_provider.dart';
import '../../collectibles/application/album_provider.dart';
import 'episode_card.dart';
import '../application/episode_progress_provider.dart';
import '../application/series_rating_provider.dart';
import '../../profile/application/profile_provider.dart';

class SeriesScreen extends ConsumerWidget {
  final String seriesId;

  const SeriesScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesProvider(seriesId));
    final seriesDetailAsync = ref.watch(seriesDetailProvider(seriesId));

    final seriesDetail = seriesDetailAsync.valueOrNull;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: episodesAsync.when(
        data: (episodes) => _EpisodeList(
          episodes: episodes,
          seriesId: seriesId,
          seriesDetail: seriesDetail,
        ),
        loading: () => _EpisodeList(
          episodes: const [],
          seriesId: seriesId,
          seriesDetail: null,
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load episodes',
            style: GoogleFonts.sora(color: textSec),
          ),
        ),
      ),
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  final List<Episode> episodes;
  final String seriesId;
  final SeriesDetail? seriesDetail;

  const _EpisodeList({
    required this.episodes,
    required this.seriesId,
    required this.seriesDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(activeRaceProvider(seriesId));
    final race = raceAsync.valueOrNull;
    // H-4 fix: use a stable one-shot provider so banner appears without layout shift
    final hasCharacters =
        ref.watch(seriesHasCharactersProvider(seriesId)).valueOrNull ?? false;

    final profileAsync = ref.watch(profileProvider);
    final isDramaPassActive = profileAsync.valueOrNull?.dramaPassActive ?? false;
    final isVipSeries = seriesDetail?.isVip ?? false;

    // Collectibles counts for Album chip
    final collectiblesAsync = ref.watch(seriesCollectiblesProvider(seriesId));
    final ownedAsync = ref.watch(ownedCollectibleIdsProvider);
    final collectibles = collectiblesAsync.valueOrNull ?? [];
    final owned = ownedAsync.valueOrNull ?? {};
    final showAlbum = collectibles.isNotEmpty;

    // Number of pinned banners before episode rows
    final bannerCount =
        (race != null ? 1 : 0) + (hasCharacters ? 1 : 0) + (showAlbum ? 1 : 0) + 1;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SeriesHeroHeader(series: seriesDetail),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              int cursor = 0;
              if (index == cursor) {
                return MarathonSeriesBanner(seriesId: seriesId);
              }
              cursor++;
              if (race != null) {
                if (index == cursor) return _RaceBanner(race: race);
                cursor++;
              }
              if (hasCharacters) {
                if (index == cursor) return _CharactersBanner(seriesId: seriesId);
                cursor++;
              }
              if (showAlbum) {
                if (index == cursor) {
                  return _AlbumBanner(
                    seriesId: seriesId,
                    ownedCount: collectibles.where((c) => owned.contains(c.id)).length,
                    total: collectibles.length,
                  );
                }
                cursor++;
              }
              final episode = episodes[index - bannerCount];
              return _EpisodeRow(
                episode: episode,
                isVipSeries: isVipSeries,
                isDramaPassActive: isDramaPassActive,
              );
            },
            childCount: episodes.length + bannerCount,
          ),
        ),
      ],
    );
  }
}

class _SeriesHeroHeader extends ConsumerWidget {
  final SeriesDetail? series;
  const _SeriesHeroHeader({this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (series == null) return const SizedBox(height: 200, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: pink, strokeWidth: 2))));
    return Stack(
      children: [
        // Hero image
        SizedBox(
          height: 220,
          width: double.infinity,
          child: series!.coverUrl != null
              ? Image.network(
                  series!.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: card),
                )
              : Container(color: card),
        ),
        // Gradient scrim
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, bgDeep],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Share button
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.ios_share, color: textCol),
            tooltip: 'Share',
            onPressed: () => shareSeries(series!.id, series!.title),
          ),
        ),
        // Metadata overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (series!.isVip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: goldGrad,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VIP',
                      style: GoogleFonts.nunito(
                        color: bgDeep,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (series!.genre != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      series!.genre!,
                      style: GoogleFonts.sora(color: textSec, fontSize: 11),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(
                series!.title,
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              if (series!.creatorId != null)
                Builder(builder: (context) {
                  final creatorAsync = ref.watch(publicCreatorProfileProvider(series!.creatorId!));
                  final displayName = creatorAsync.valueOrNull?['display_name'] as String?;
                  if (displayName == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      Posthog().capture(
                        eventName: 'creator_profile_tapped',
                        properties: {'creator_id': series!.creatorId},
                      );
                      context.push('/creator/${series!.creatorId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'by $displayName',
                        style: GoogleFonts.sora(color: textSec, fontSize: 12),
                      ),
                    ),
                  );
                }),
              if (series!.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  series!.description!,
                  style: GoogleFonts.sora(color: textSec, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${series!.totalEpisodes} episodes',
                style: GoogleFonts.sora(color: textDim, fontSize: 11),
              ),
              // Rating display — only shown when there are ratings
              Builder(builder: (context) {
                final ratingState = ref.watch(seriesRatingProvider(series!.id)).valueOrNull;
                if (ratingState == null || ratingState.ratingCount == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${ratingState.avgRating.toStringAsFixed(1)} (${ratingState.ratingCount})',
                        style: GoogleFonts.sora(color: textSec, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  final Episode episode;
  final bool isVipSeries;
  final bool isDramaPassActive;

  const _EpisodeRow({
    super.key,
    required this.episode,
    required this.isVipSeries,
    required this.isDramaPassActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(episodeUnlockedProvider(episode.id));
    final isUnlocked = unlockedAsync.valueOrNull ?? false;

    final progressMap = ref.watch(seriesProgressProvider(episode.seriesId)).valueOrNull ?? {};
    final epProgress = progressMap[episode.id];

    return EpisodeCard(
      episode: episode,
      isUnlocked: isUnlocked,
      isCompleted: epProgress?.completed ?? false,
      progressPct: epProgress?.progressPct ?? 0,
      onTap: () => _handleTap(context, ref, isUnlocked),
    );
  }

  void _showVipGate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: Text('VIP Series', style: GoogleFonts.nunito(color: gold, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          'This series is exclusive to Drama Pass subscribers.',
          style: GoogleFonts.sora(color: textSec, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Later', style: GoogleFonts.sora(color: textDim))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GBtn(
              gradient: goldGrad,
              width: double.infinity,
              onPressed: () {
                Navigator.pop(context);
                context.push('/pass');
              },
              child: Text(
                'Unlock with Drama Pass →',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, bool isUnlocked) async {
    // VIP series gate — must have Drama Pass to unlock episodes
    if (isVipSeries && !isDramaPassActive && !episode.isFree) {
      _showVipGate(context);
      return;
    }

    final accessible = episode.isFree || isUnlocked;

    if (accessible) {
      context.push('/series/${episode.seriesId}/episode/${episode.id}',
          extra: episode);
      return;
    }

    // Attempt unlock
    final energy = ref.read(energyStateProvider);
    if (energy.current < episode.energyCost) {
      await EnergyGate.show(
        context,
        currentEnergy: energy.current,
        episode: episode.coinCost > 0 ? episode : null,
      );
      return;
    }

    final requestId = _generateRequestId();
    final notifier = ref.read(unlockEpisodeProvider(episode.id).notifier);
    final result = await notifier.unlock(requestId);

    if (!context.mounted) return;

    if (result.isSuccess) {
      context.push('/series/${episode.seriesId}/episode/${episode.id}',
          extra: episode);
    } else if (result.status == WatchResultStatus.insufficientEnergy) {
      await EnergyGate.show(
        context,
        currentEnergy: result.currentEnergy ?? 0,
        episode: episode.coinCost > 0 ? episode : null,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Failed to unlock episode',
            style: GoogleFonts.sora(color: textCol),
          ),
          backgroundColor: surface,
        ),
      );
    }
  }

  String _generateRequestId() {
    final rng = Random.secure();
    final bytes = List.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

// ---------------------------------------------------------------------------
// Album banner — "Album (x/y)" chip that navigates to /series/:id/album
// ---------------------------------------------------------------------------

class _AlbumBanner extends StatelessWidget {
  final String seriesId;
  final int ownedCount;
  final int total;

  const _AlbumBanner({
    required this.seriesId,
    required this.ownedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/$seriesId/album'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: purpleDim),
        ),
        child: Row(
          children: [
            const Text('🃏', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Album ($ownedCount/$total)',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CharactersBanner extends StatelessWidget {
  final String seriesId;

  const _CharactersBanner({required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/affinity/$seriesId'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: purpleDim),
        ),
        child: Row(
          children: [
            const Text('💙', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Character Relationships',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

// H-3 fix: ConsumerWidget so it can check participation status for correct subtitle
class _RaceBanner extends ConsumerWidget {
  final Race race;

  const _RaceBanner({required this.race});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParticipant = ref.watch(raceParticipantProvider(race.id)).valueOrNull ?? false;

    return GestureDetector(
      onTap: () => context.push('/race/${race.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: purpleGrad,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    race.title,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isParticipant
                        ? 'You\'re racing · tap to view leaderboard'
                        : 'Drama Sprint active · tap to join',
                    style: GoogleFonts.sora(
                      color: textSec,
                      fontSize: 11,
                    ),
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
