import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../energy/presentation/energy_gate.dart';
import '../../energy/application/energy_provider.dart';
import '../application/episodes_provider.dart';
import '../application/series_detail_provider.dart';
import '../domain/episode.dart';
import '../../energy/domain/watch_result.dart';
import '../../affinity/application/affinity_provider.dart'
    show seriesHasCharactersProvider;
import '../../race/application/race_provider.dart';
import '../../race/domain/race.dart';
import 'episode_card.dart';

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

    // Number of pinned banners before episode rows
    final bannerCount = (race != null ? 1 : 0) + (hasCharacters ? 1 : 0);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SeriesHeroHeader(series: seriesDetail),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (race != null && index == 0) {
                return _RaceBanner(race: race, ref: ref);
              }
              if (hasCharacters && index == (race != null ? 1 : 0)) {
                return _CharactersBanner(seriesId: seriesId);
              }
              final episode = episodes[index - bannerCount];
              return _EpisodeRow(episode: episode);
            },
            childCount: episodes.length + bannerCount,
          ),
        ),
      ],
    );
  }
}

class _SeriesHeroHeader extends StatelessWidget {
  final SeriesDetail? series;
  const _SeriesHeroHeader({this.series});

  @override
  Widget build(BuildContext context) {
    if (series == null) return const SizedBox(height: 200);
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
            ],
          ),
        ),
      ],
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  final Episode episode;

  const _EpisodeRow({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(episodeUnlockedProvider(episode.id));
    final isUnlocked = unlockedAsync.valueOrNull ?? false;

    return EpisodeCard(
      episode: episode,
      isUnlocked: isUnlocked,
      onTap: () => _handleTap(context, ref, isUnlocked),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, bool isUnlocked) async {
    final accessible = episode.isFree || isUnlocked;

    if (accessible) {
      context.push('/series/${episode.seriesId}/episode/${episode.id}',
          extra: episode);
      return;
    }

    // Attempt unlock
    final energy = ref.read(energyStateProvider);
    if (energy.current < episode.energyCost) {
      await EnergyGate.show(context, currentEnergy: energy.current);
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
      await EnergyGate.show(context, currentEnergy: result.currentEnergy ?? 0);
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
  final WidgetRef ref;

  const _RaceBanner({required this.race, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final isParticipant = widgetRef.watch(raceParticipantProvider(race.id)).valueOrNull ?? false;

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
