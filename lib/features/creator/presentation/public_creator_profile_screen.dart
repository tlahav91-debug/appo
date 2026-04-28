import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_provider.dart';

class PublicCreatorProfileScreen extends ConsumerStatefulWidget {
  final String creatorId;
  const PublicCreatorProfileScreen({super.key, required this.creatorId});

  @override
  ConsumerState<PublicCreatorProfileScreen> createState() => _PublicCreatorProfileScreenState();
}

class _PublicCreatorProfileScreenState extends ConsumerState<PublicCreatorProfileScreen> {
  bool _followLoading = false;

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    setState(() => _followLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _followLoading = false); return; }
    try {
      if (currentlyFollowing) {
        await Supabase.instance.client
            .from('creator_follows')
            .delete()
            .eq('follower_id', userId)
            .eq('creator_id', widget.creatorId);
      } else {
        await Supabase.instance.client
            .from('creator_follows')
            .insert({'follower_id': userId, 'creator_id': widget.creatorId});
      }
      ref.invalidate(creatorFollowStateProvider(widget.creatorId));
      ref.invalidate(publicCreatorProfileProvider(widget.creatorId));
    } catch (_) {}
    setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicCreatorProfileProvider(widget.creatorId));
    final seriesAsync = ref.watch(creatorSeriesProvider(widget.creatorId));
    final followAsync = ref.watch(creatorFollowStateProvider(widget.creatorId));

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: Text('Creator not found', style: GoogleFonts.sora(color: textDim))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Creator not found', style: GoogleFonts.sora(color: textDim)));
          }
          final displayName = profile['display_name'] as String;
          final bio = profile['bio'] as String;
          final avatarUrl = profile['avatar_url'] as String?;
          final followerCount = (profile['follower_count'] as num).toInt();
          final isFollowing = followAsync.valueOrNull ?? false;

          return RefreshIndicator(
            color: gold,
            onRefresh: () async {
              ref.invalidate(publicCreatorProfileProvider(widget.creatorId));
              ref.invalidate(creatorSeriesProvider(widget.creatorId));
              ref.invalidate(creatorFollowStateProvider(widget.creatorId));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar + name + follow
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: surface,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(displayName[0].toUpperCase(), style: GoogleFonts.nunito(color: textCol, fontSize: 24, fontWeight: FontWeight.w800))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20)),
                          Text('$followerCount follower${followerCount == 1 ? '' : 's'}',
                              style: GoogleFonts.sora(color: textSec, fontSize: 13)),
                        ],
                      ),
                    ),
                    _followLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: gold, strokeWidth: 2))
                        : OutlinedButton(
                            onPressed: () => _toggleFollow(isFollowing),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isFollowing ? textSec : gold,
                              side: BorderSide(color: isFollowing ? textSec : gold),
                            ),
                            child: Text(isFollowing ? 'Following' : 'Follow'),
                          ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(bio, style: GoogleFonts.sora(color: textSec, fontSize: 14)),
                const SizedBox(height: 24),
                Text('Series', style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                seriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: gold)),
                  error: (e, _) => Text('Failed to load series', style: GoogleFonts.sora(color: textDim)),
                  data: (seriesList) {
                    if (seriesList.isEmpty) {
                      return Text('No series yet.', style: GoogleFonts.sora(color: textDim, fontSize: 13));
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: seriesList.length,
                      itemBuilder: (context, i) {
                        final s = seriesList[i];
                        final thumb = s['thumbnail_url'] as String?;
                        return Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            image: thumb != null
                                ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)
                                : null,
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgDeep.withOpacity(0.7),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                s['title'] as String,
                                style: GoogleFonts.sora(color: textCol, fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
