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
import '../domain/episode.dart';
import '../../energy/domain/watch_result.dart';
import '../../affinity/application/affinity_provider.dart';
import '../../race/application/race_provider.dart';
import '../../race/domain/race.dart';
import 'episode_card.dart';

class SeriesScreen extends ConsumerWidget {
  final String seriesId;

  const SeriesScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesProvider(seriesId));

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: episodesAsync.when(
        data: (episodes) => _EpisodeList(episodes: episodes, seriesId: seriesId),
        loading: () => const Center(
          child: CircularProgressIndicator(color: pink),
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

  const _EpisodeList({required this.episodes, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(activeRaceProvider(seriesId));
    final race = raceAsync.valueOrNull;
    final affinitiesAsync = ref.watch(characterAffinitiesProvider(seriesId));
    final hasCharacters = (affinitiesAsync.valueOrNull ?? []).isNotEmpty;

    // Number of pinned banners before episode rows
    final bannerCount = (race != null ? 1 : 0) + (hasCharacters ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: episodes.length + bannerCount,
      itemBuilder: (context, index) {
        if (race != null && index == 0) {
          return _RaceBanner(race: race, ref: ref);
        }
        if (hasCharacters && index == (race != null ? 1 : 0)) {
          return _CharactersBanner(seriesId: seriesId);
        }
        final episode = episodes[index - bannerCount];
        return _EpisodeRow(episode: episode);
      },
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
