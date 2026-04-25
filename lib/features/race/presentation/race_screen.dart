import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/race_provider.dart';
import '../domain/race.dart';
import 'race_leaderboard_card.dart';

class RaceScreen extends ConsumerStatefulWidget {
  final String raceId;

  const RaceScreen({super.key, required this.raceId});

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends ConsumerState<RaceScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(Race race) {
    _countdownTimer?.cancel();
    _timeRemaining = race.timeRemaining;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeRemaining = race.timeRemaining;
      });
      if (_timeRemaining == Duration.zero) {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final raceAsync = ref.watch(raceByIdProvider(widget.raceId));
    final leaderboardAsync = ref.watch(raceLeaderboardProvider(widget.raceId));
    final participantAsync = ref.watch(raceParticipantProvider(widget.raceId));
    final joinAsync = ref.watch(raceJoinProvider);
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: bgDeep,
      body: raceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purple)),
        error: (e, _) => Center(
          child: Text('Failed to load race', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (race) {
          if (race == null) {
            return Center(
              child: Text('Race not found', style: GoogleFonts.sora(color: textDim)),
            );
          }

          // Start countdown once
          if (_countdownTimer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown(race));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: bgDeep,
                foregroundColor: textCol,
                expandedHeight: 160,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B0FA0), Color(0xFF080612)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Text('⚡', style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            race.title,
                            style: GoogleFonts.nunito(
                              color: textCol,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          _CountdownBadge(remaining: _timeRemaining),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Join button
              participantAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (isParticipant) {
                  if (isParticipant || !race.isLive) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: _StatusBadge(
                          isParticipant: isParticipant,
                          isLive: race.isLive,
                        ),
                      ),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: GestureDetector(
                        onTap: joinAsync.isLoading
                            ? null
                            : () => ref.read(raceJoinProvider.notifier).join(widget.raceId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: purpleGrad,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: joinAsync.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: textCol),
                                  )
                                : Text(
                                    'Join Race',
                                    style: GoogleFonts.nunito(
                                      color: textCol,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Leaderboard header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Leaderboard',
                    style: GoogleFonts.nunito(
                      color: textSec,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              // Leaderboard list
              leaderboardAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: purple),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Failed to load leaderboard',
                        style: GoogleFonts.sora(color: textDim),
                      ),
                    ),
                  ),
                ),
                data: (participants) {
                  if (participants.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              const Text('🏁', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(
                                'No participants yet\nBe the first to join!',
                                style: GoogleFonts.sora(color: textDim, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = participants[i];
                        return RaceLeaderboardCard(
                          participant: p,
                          position: i + 1,
                          isMe: p.userId == myId,
                        );
                      },
                      childCount: participants.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final Duration remaining;

  const _CountdownBadge({required this.remaining});

  @override
  Widget build(BuildContext context) {
    if (remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: pinkDim,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Race Ended',
          style: GoogleFonts.sora(color: pink, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final label = h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: purpleDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '⏱ $label',
        style: GoogleFonts.sora(color: purple, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isParticipant;
  final bool isLive;

  const _StatusBadge({required this.isParticipant, required this.isLive});

  @override
  Widget build(BuildContext context) {
    if (!isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            'This race has ended',
            style: GoogleFonts.sora(color: textDim, fontSize: 14),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: greenDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green),
      ),
      child: Center(
        child: Text(
          '✓ You\'re in this race',
          style: GoogleFonts.nunito(
            color: green,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
