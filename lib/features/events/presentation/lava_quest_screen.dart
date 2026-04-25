import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/application/profile_provider.dart';
import '../application/lava_quest_provider.dart';
import '../domain/lava_quest.dart';

class LavaQuestScreen extends ConsumerStatefulWidget {
  final String questId;

  const LavaQuestScreen({super.key, required this.questId});

  @override
  ConsumerState<LavaQuestScreen> createState() => _LavaQuestScreenState();
}

class _LavaQuestScreenState extends ConsumerState<LavaQuestScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  late AnimationController _progressController;
  late Animation<double> _progressAnim;
  double _lastFraction = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startCountdown(LavaQuest quest) {
    _countdownTimer?.cancel();
    _timeRemaining = quest.timeRemaining;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeRemaining = quest.timeRemaining);
      if (_timeRemaining == Duration.zero) _countdownTimer?.cancel();
    });
  }

  void _animateProgress(double fraction) {
    if ((fraction - _lastFraction).abs() < 0.001) return;
    _progressAnim = Tween<double>(begin: _lastFraction, end: fraction).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _lastFraction = fraction;
    _progressController.forward(from: 0);
  }

  Future<void> _claim(LavaQuest quest) async {
    try {
      final result = await ref.read(questClaimProvider(widget.questId).notifier).claim();
      if (!mounted) return;
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '🌋 Quest complete! +${result['gems_earned']} 💎  +${result['coins_earned']} 🪙',
          style: GoogleFonts.sora(color: textCol),
        ),
        backgroundColor: lavaDim,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.sora(color: textCol)),
        backgroundColor: surface,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questAsync = ref.watch(questByIdProvider(widget.questId));
    final claimAsync = ref.watch(questClaimProvider(widget.questId));

    return Scaffold(
      backgroundColor: bgDeep,
      body: questAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: lava)),
        error: (e, _) => Center(
          child: Text('Failed to load quest', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (quest) {
          if (quest == null) {
            return Center(
              child: Text('Quest not found', style: GoogleFonts.sora(color: textDim)),
            );
          }

          if (_countdownTimer == null) {
            _timeRemaining = quest.timeRemaining;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _startCountdown(quest);
                _animateProgress(quest.progressFraction);
              }
            });
          } else {
            _animateProgress(quest.progressFraction);
          }

          final h = _timeRemaining.inHours;
          final m = _timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
          final s = _timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
          final countdownLabel = h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: bgDeep,
                foregroundColor: textCol,
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8A1A00), Color(0xFF080612)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Text('🌋', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 6),
                          Text(
                            quest.title,
                            style: GoogleFonts.nunito(
                              color: textCol,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: lavaDim,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              quest.timeRemaining == Duration.zero
                                  ? 'Expired'
                                  : '⏱ $countdownLabel remaining',
                              style: GoogleFonts.sora(
                                  color: lava,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quest.description != null) ...[
                        Text(
                          quest.description!,
                          style: GoogleFonts.sora(color: textSec, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Progress section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.nunito(
                              color: textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${quest.progress} / ${quest.goalValue} episodes',
                            style: GoogleFonts.nunito(
                              color: quest.isCompleted ? green : lava,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            minHeight: 12,
                            backgroundColor: border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              quest.isCompleted ? green : lava,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Reward section
                      Text(
                        'Reward',
                        style: GoogleFonts.nunito(
                          color: textSec,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _RewardChip(
                            emoji: '💎',
                            amount: '${quest.rewardGems}',
                            color: cyan,
                          ),
                          const SizedBox(width: 16),
                          _RewardChip(
                            emoji: '🪙',
                            amount: '${quest.rewardCoins}',
                            color: gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // CTA
                      if (quest.isRewardClaimed)
                        _StatusBox(
                          label: '✓ Reward Collected',
                          color: green,
                          bgColor: greenDim,
                        )
                      else if (quest.isCompleted)
                        GestureDetector(
                          onTap: claimAsync.isLoading ? null : () => _claim(quest),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: lavaGrad,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: claimAsync.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: textCol),
                                    )
                                  : Text(
                                      '🌋 Claim Reward',
                                      style: GoogleFonts.nunito(
                                        color: textCol,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      else
                        _StatusBox(
                          label: 'Keep watching to complete this quest',
                          color: textDim,
                          bgColor: card,
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String emoji;
  final String amount;
  final Color color;

  const _RewardChip({required this.emoji, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            amount,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBox(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.sora(color: color, fontSize: 14),
        ),
      ),
    );
  }
}
