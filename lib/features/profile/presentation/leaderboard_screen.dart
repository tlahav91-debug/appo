import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';
import '../application/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          Positioned.fill(
            child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    'Rankings',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    gradient: pinkFull,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textDim,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '⭐ Fan Level'),
                    Tab(text: '⚡ Race'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _FanLevelTab(myId: myId),
                    _RaceTab(myId: myId),
                  ],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

class _FanLevelTab extends ConsumerWidget {
  final String? myId;
  const _FanLevelTab({this.myId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fanLevelLeaderboardProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: pink, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Text('Failed to load', style: GoogleFonts.sora(color: textDim)),
      ),
      data: (entries) =>
          _LeaderboardList(entries: entries, myId: myId, scoreLabel: 'XP'),
    );
  }
}

class _RaceTab extends ConsumerWidget {
  final String? myId;
  const _RaceTab({this.myId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(raceLeaderboardProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: pink, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Text('Failed to load', style: GoogleFonts.sora(color: textDim)),
      ),
      data: (result) {
        if (result.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'No race active',
                  style: GoogleFonts.nunito(
                    color: textDim,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Join a Drama Sprint to compete',
                  style: GoogleFonts.sora(color: textDim, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                result.raceTitle,
                style: GoogleFonts.nunito(
                  color: purple,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _LeaderboardList(
                entries: result.entries,
                myId: myId,
                scoreLabel: 'eps',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? myId;
  final String scoreLabel;

  const _LeaderboardList({
    required this.entries,
    this.myId,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final isMe = e.userId == myId;
        return _RankRow(entry: e, isMe: isMe, scoreLabel: scoreLabel);
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final String scoreLabel;

  const _RankRow({
    required this.entry,
    required this.isMe,
    required this.scoreLabel,
  });

  Color get _rankColor => switch (entry.rank) {
        1 => gold,
        2 => const Color(0xFFC0C0C0), // silver — no design token exists
        3 => const Color(0xFFCD7F32), // bronze — no design token exists
        _ => textDim,
      };

  String get _rankEmoji => switch (entry.rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#${entry.rank}',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? pink.withOpacity(0.12) : card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? pink : border),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? Text(
                    _rankEmoji,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    _rankEmoji,
                    style: GoogleFonts.nunito(
                      color: _rankColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: cardHi),
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: textDim, size: 18),
                    ),
                  )
                : const Icon(Icons.person, color: textDim, size: 18),
          ),
          const SizedBox(width: 10),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: GoogleFonts.nunito(
                        color: isMe ? pink : textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(you)',
                        style: GoogleFonts.sora(color: pink, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                if (entry.fanLevel != null)
                  Text(
                    'Lv.${entry.fanLevel}',
                    style: GoogleFonts.sora(color: textDim, fontSize: 11),
                  ),
              ],
            ),
          ),
          // Score
          Text(
            '${entry.score} $scoreLabel',
            style: GoogleFonts.nunito(
              color: gold,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
