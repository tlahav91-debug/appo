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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
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
