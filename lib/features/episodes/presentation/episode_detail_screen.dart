import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/choice_sheet.dart';
import '../application/episodes_provider.dart';
import '../application/episode_progress_provider.dart';
import '../domain/episode.dart';
import 'reaction_row.dart';
import '../application/comments_provider.dart';
import 'comments_sheet.dart';
import '../application/series_rating_provider.dart';
import '../../social/application/social_provider.dart';
import '../../achievements/application/achievements_provider.dart';
import '../../collectibles/application/album_provider.dart';
import '../../profile/application/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EpisodeDetailScreen extends ConsumerStatefulWidget {
  final Episode episode;

  const EpisodeDetailScreen({super.key, required this.episode});

  @override
  ConsumerState<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends ConsumerState<EpisodeDetailScreen> {
  bool _done = false;

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
    // Trigger notification soft-ask check (fire-and-forget)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(notificationServiceProvider).onEpisodeViewed(context);
    });
  }

  void _onDone() {
    ref.invalidate(seriesProgressProvider(widget.episode.seriesId));
    if (mounted) setState(() => _done = true);
    ref.read(socialRepositoryProvider).createActivityEvent(
      widget.episode.id,
      widget.episode.seriesId,
    );
    _mintCollectible();
  }

  Future<void> _mintCollectible() async {
    try {
      final service = ref.read(collectibleServiceProvider);
      final result = await service.mintForEpisode(widget.episode.id);
      if (!result.alreadyOwned && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🃏 Card unlocked!',
              style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
            ),
            backgroundColor: surface,
            duration: const Duration(seconds: 3),
          ),
        );
        // Invalidate so album reflects new card immediately
        ref.invalidate(ownedCollectibleIdsProvider);
      }
    } catch (_) {
      // Mint errors are non-blocking — never interrupt the user flow
    }
  }

  void _showCompletionModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => _SeriesCompletionModal(episode: widget.episode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final choicesAsync = ref.watch(episodeChoicesProvider(widget.episode.id));
    final unlockedAsync = ref.watch(episodeUnlockedProvider(widget.episode.id));
    final isUnlocked = unlockedAsync.isLoading ? true : (unlockedAsync.valueOrNull ?? false);

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
                ],
                ReactionRow(episodeId: widget.episode.id),
                const SizedBox(height: 12),
                _CommentCountButton(episodeId: widget.episode.id),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _done
          ? _NextEpisodeBar(
              currentEpisode: widget.episode,
              onSeriesComplete: _showCompletionModal,
            )
          : _ChoiceBar(
              episode: widget.episode,
              choicesAsync: choicesAsync,
              isUnlocked: isUnlocked,
              onDone: _onDone,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChoiceBar — modified to support "Continue →" for episodes with no choices
// and to await ChoiceSheet then call onDone.
// ---------------------------------------------------------------------------

class _ChoiceBar extends StatelessWidget {
  final Episode episode;
  final AsyncValue choicesAsync;
  final bool isUnlocked;
  final VoidCallback onDone;

  const _ChoiceBar({
    required this.episode,
    required this.choicesAsync,
    required this.isUnlocked,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: choicesAsync.when(
        data: (choices) {
          // Empty choices: RLS denied access (non-free + not unlocked) or episode has no choices (e.g. series finale)
          if (choices.isEmpty && !episode.isFree && !isUnlocked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: textDim, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Unlock this episode to continue',
                  style: GoogleFonts.sora(color: textDim, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          if (choices.isEmpty) {
            // No choices — show "Continue →" that marks episode done
            return GestureDetector(
              onTap: onDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: pinkFull,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Continue →',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }

          // Has choices — open ChoiceSheet then mark done on close
          return GestureDetector(
            onTap: () async {
              await ChoiceSheet.show(
                context,
                episodeId: episode.id,
                choices: choices,
              );
              if (context.mounted) onDone();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: pinkFull,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Make Your Choice',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
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

// ---------------------------------------------------------------------------
// _NextEpisodeBar — auto-advance countdown bar shown after episode is done
// ---------------------------------------------------------------------------

class _NextEpisodeBar extends ConsumerStatefulWidget {
  final Episode currentEpisode;
  final VoidCallback onSeriesComplete;

  const _NextEpisodeBar({
    required this.currentEpisode,
    required this.onSeriesComplete,
  });

  @override
  ConsumerState<_NextEpisodeBar> createState() => _NextEpisodeBarState();
}

class _NextEpisodeBarState extends ConsumerState<_NextEpisodeBar> {
  Timer? _timer;
  int _countdown = 5;
  Episode? _nextEp;
  bool _isLastEpisode = false;

  @override
  void initState() {
    super.initState();
    // Defer episode lookup until first frame so ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Force-load episodes in case user navigated here directly (BUG-030-H-1 fix)
    final allEpisodes = await ref.read(
      episodesProvider(widget.currentEpisode.seriesId).future,
    );
    final nextEp = allEpisodes.cast<Episode?>().firstWhere(
      (e) => e!.episodeNumber == widget.currentEpisode.episodeNumber + 1,
      orElse: () => null,
    );
    if (!mounted) return;
    setState(() {
      _nextEp = nextEp;
      _isLastEpisode = nextEp == null;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        if (_isLastEpisode) {
          widget.onSeriesComplete();
        } else if (_nextEp != null) {
          _goToNext(_nextEp!);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToNext(Episode nextEp) {
    _timer?.cancel();
    context.push('/series/${nextEp.seriesId}/episode/${nextEp.id}', extra: nextEp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLastEpisode) ...[
            // Series complete state
            Text(
              'Series Complete! 🎉',
              style: GoogleFonts.nunito(
                color: textCol,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                widget.onSeriesComplete();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: pinkFull,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'View Completion Reward',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Next episode countdown
            Row(
              children: [
                Text(
                  'Up Next',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '$_countdown s',
                  style: GoogleFonts.nunito(
                    color: gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_nextEp != null) ...[
              Text(
                _nextEp!.title,
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Episode ${_nextEp!.episodeNumber}',
                style: GoogleFonts.sora(color: textSec, fontSize: 12),
              ),
            ] else ...[
              // Episodes list still loading
              Text(
                'Loading...',
                style: GoogleFonts.sora(color: textDim, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _nextEp != null ? () => _goToNext(_nextEp!) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: pinkFull,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Next Episode →',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Back to Series',
                      style: GoogleFonts.nunito(
                        color: textSec,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SeriesCompletionModal — full-screen celebration dialog with star rating
// ---------------------------------------------------------------------------

class _SeriesCompletionModal extends ConsumerStatefulWidget {
  final Episode episode;
  const _SeriesCompletionModal({required this.episode});

  @override
  ConsumerState<_SeriesCompletionModal> createState() => _SeriesCompletionModalState();
}

class _SeriesCompletionModalState extends ConsumerState<_SeriesCompletionModal> {
  int? _selectedRating;
  bool _ratingSubmitted = false;

  bool _rewardLoading = true;
  bool _alreadyClaimed = false;
  int _coinsGranted = 0;
  int _xpGranted = 0;
  bool _leveledUp = false;

  @override
  void initState() {
    super.initState();
    _claimReward();
  }

  Future<void> _claimReward() async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'claim-series-completion',
        body: {'series_id': widget.episode.seriesId},
      );
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _alreadyClaimed = data['already_claimed'] as bool? ?? false;
          _coinsGranted = (data['coins_granted'] as num?)?.toInt() ?? 0;
          _xpGranted = (data['xp_granted'] as num?)?.toInt() ?? 0;
          _leveledUp = data['leveled_up'] as bool? ?? false;
          _rewardLoading = false;
        });
        if (!_alreadyClaimed) {
          ref.invalidate(profileProvider);
          ref.invalidate(seriesCompletionsProvider);
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null) ref.invalidate(userAchievementsProvider(uid));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _rewardLoading = false);
    }
  }

  Future<void> _rate(int stars) async {
    setState(() => _selectedRating = stars);
    await ref.read(ratingServiceProvider).submitRating(widget.episode.seriesId, stars);
    ref.invalidate(seriesRatingProvider(widget.episode.seriesId));
    if (mounted) setState(() => _ratingSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgDeep, surface],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('Series Complete!', style: GoogleFonts.nunito(color: gold, fontWeight: FontWeight.w900, fontSize: 28)),
                const SizedBox(height: 8),
                Text('You\'ve finished all episodes.', style: GoogleFonts.sora(color: textSec, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                if (_rewardLoading)
                  const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                  )
                else if (_alreadyClaimed)
                  Text('✓ Reward already claimed', style: GoogleFonts.sora(color: textDim, fontSize: 13))
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '🪙 +$_coinsGranted coins  ⭐ +$_xpGranted XP',
                      style: GoogleFonts.nunito(color: gold, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  if (_leveledUp) ...[
                    const SizedBox(height: 8),
                    Text('🎉 Level Up!', style: GoogleFonts.nunito(color: pink, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ],
                const SizedBox(height: 24),
                // Star rating
                Text(
                  _ratingSubmitted ? 'Thanks for rating!' : 'Rate this series',
                  style: GoogleFonts.sora(color: textSec, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final filled = _selectedRating != null && star <= _selectedRating!;
                    return GestureDetector(
                      onTap: _ratingSubmitted ? null : () => _rate(star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? gold : textDim,
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: pinkFull, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text('Find Another Series', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  child: Text('Back to Home', style: GoogleFonts.sora(color: textDim, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CommentCountButton — shows live comment count, opens CommentsSheet on tap
// ---------------------------------------------------------------------------

class _CommentCountButton extends ConsumerWidget {
  final String episodeId;

  const _CommentCountButton({required this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentCountAsync = ref.watch(commentCountProvider(episodeId));
    final commentCount = commentCountAsync.valueOrNull ?? 0;

    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.chat_bubble_outline, color: textSec, size: 18),
      label: Text(
        '$commentCount',
        style: const TextStyle(color: textSec),
      ),
      onPressed: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CommentsSheet(episodeId: episodeId),
        );
        ref.invalidate(commentCountProvider(episodeId));
      },
    );
  }
}
