import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/choice_sheet.dart';
import '../application/episodes_provider.dart';
import '../domain/episode.dart';
import 'reaction_row.dart';

class EpisodeDetailScreen extends ConsumerStatefulWidget {
  final Episode episode;

  const EpisodeDetailScreen({super.key, required this.episode});

  @override
  ConsumerState<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends ConsumerState<EpisodeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).capture('episode_viewed', properties: {
        'episode_id': widget.episode.id,
        'series_id': widget.episode.seriesId,
        'episode_number': widget.episode.episodeNumber,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final choicesAsync = ref.watch(episodeChoicesProvider(widget.episode.id));

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: CustomScrollView(
        slivers: [
          // Hero thumbnail
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.episode.thumbnailUrl != null
                  ? Image.network(widget.episode.thumbnailUrl!, fit: BoxFit.cover)
                  : Container(
                      color: card,
                      child: const Icon(Icons.movie_outlined, color: textDim, size: 48),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Episode ${widget.episode.episodeNumber}',
                  style: GoogleFonts.sora(color: textDim, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.episode.title,
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.episode.synopsis != null) ...[
                  Text(
                    widget.episode.synopsis!,
                    style: GoogleFonts.sora(
                      color: textSec,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ReactionRow(episodeId: widget.episode.id),
                  const SizedBox(height: 100),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ChoiceBar(episode: widget.episode, choicesAsync: choicesAsync),
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  final Episode episode;
  final AsyncValue choicesAsync;

  const _ChoiceBar({required this.episode, required this.choicesAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: choicesAsync.when(
        data: (choices) => GestureDetector(
          onTap: choices.isEmpty
              ? null
              : () => ChoiceSheet.show(
                    context,
                    episodeId: episode.id,
                    choices: choices,
                  ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: choices.isEmpty ? null : pinkFull,
              color: choices.isEmpty ? cardHi : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                choices.isEmpty ? 'No choices available' : 'Make Your Choice',
                style: GoogleFonts.nunito(
                  color: choices.isEmpty ? textDim : textCol,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        loading: () => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: cardHi, borderRadius: BorderRadius.circular(14)),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: textSec),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
