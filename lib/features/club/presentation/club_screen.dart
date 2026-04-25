import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/club_provider.dart';
import '../domain/club_member.dart';
import '../domain/watch_club.dart';

class ClubScreen extends ConsumerWidget {
  final String clubId;

  const ClubScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userClubAsync = ref.watch(userClubProvider);
    final leaderboardAsync = ref.watch(clubLeaderboardProvider(clubId));
    final actionAsync = ref.watch(clubActionProvider);
    final myId = Supabase.instance.client.auth.currentUser?.id;

    // Club data — prefer from userClubProvider (has ownerId), fall back to leaderboard context
    final club = userClubAsync.valueOrNull;

    return Scaffold(
      backgroundColor: bgDeep,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bgDeep,
            foregroundColor: textCol,
            expandedHeight: 150,
            pinned: true,
            actions: [
              if (club != null)
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: textSec),
                  tooltip: 'Copy invite code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: club.id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Club ID copied!',
                          style: GoogleFonts.sora(color: textCol)),
                      backgroundColor: surface,
                    ));
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004A60), Color(0xFF080612)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                club?.name ?? '…',
                                style: GoogleFonts.nunito(
                                  color: textCol,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${club?.memberCount ?? 0}/20',
                              style: GoogleFonts.sora(
                                  color: textSec, fontSize: 12),
                            ),
                          ],
                        ),
                        if (club?.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            club!.description!,
                            style: GoogleFonts.sora(
                                color: textSec, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Week label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'This Week\'s Leaderboard',
                style: GoogleFonts.nunito(
                  color: textSec,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // Leaderboard
          leaderboardAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: cyan)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Failed to load members',
                      style: GoogleFonts.sora(color: textDim)),
                ),
              ),
            ),
            data: (members) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _MemberRow(
                  member: members[i],
                  position: i + 1,
                  isMe: members[i].userId == myId,
                ),
                childCount: members.length,
              ),
            ),
          ),
          // Leave button
          if (club != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: TextButton(
                  onPressed: actionAsync.isLoading
                      ? null
                      : () => _confirmLeave(context, ref, club),
                  child: Text(
                    'Leave Club',
                    style: GoogleFonts.sora(
                        color: textDim.withAlpha(180), fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(
      BuildContext context, WidgetRef ref, WatchClub club) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: Text('Leave Club?',
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w800)),
        content: Text(
          club.ownerId == Supabase.instance.client.auth.currentUser?.id
              ? 'You are the owner. Ownership will transfer to the next member.'
              : 'You will lose your spot in "${club.name}".',
          style: GoogleFonts.sora(color: textSec, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.sora(color: textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave',
                style: GoogleFonts.sora(
                    color: pink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(clubActionProvider.notifier).leave(clubId);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString(),
                style: GoogleFonts.sora(color: textCol)),
            backgroundColor: surface,
          ));
        }
      }
    }
  }
}

class _MemberRow extends StatelessWidget {
  final ClubMember member;
  final int position;
  final bool isMe;

  const _MemberRow(
      {required this.member, required this.position, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isTop3 = position <= 3;
    final medal = position == 1 ? '🥇' : position == 2 ? '🥈' : '🥉';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? cyanDim : card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMe ? cyan : (isTop3 ? border : border), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: isTop3
                ? Text(medal, style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center)
                : Text('#$position',
                    style: GoogleFonts.nunito(
                        color: textDim,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: cyanDim,
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.displayName.isNotEmpty
                        ? member.displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    member.displayName,
                    style: GoogleFonts.nunito(
                      color: isMe ? textCol : textSec,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (member.isOwner) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: goldDim,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Owner',
                        style: GoogleFonts.sora(
                            color: gold, fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.episodesThisWeek}',
                style: GoogleFonts.nunito(
                  color: isTop3 ? cyan : textSec,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text('eps',
                  style: GoogleFonts.sora(color: textDim, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
