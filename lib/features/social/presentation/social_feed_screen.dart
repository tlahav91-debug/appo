import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/social_provider.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  Set<String> _likedIds = {}; // current UI state (optimistic)
  Set<String> _serverLikedIds = {}; // synced from server payload
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  }

  void _syncLikedIds(List<Map<String, dynamic>> items) {
    final uid = _currentUserId;
    if (uid == null) return;
    final newLiked = <String>{};
    for (final item in items) {
      final likes = item['activity_likes'] as List? ?? [];
      if (likes.any((l) => (l as Map)['user_id'] == uid)) {
        newLiked.add(item['id'] as String);
      }
    }
    _serverLikedIds = Set<String>.from(newLiked);
    _likedIds = Set<String>.from(newLiked);
  }

  String _timeAgo(String isoDate) {
    final diff = DateTime.now().difference(DateTime.parse(isoDate));
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(socialFeedProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        title: Text(
          "Friends' Activity",
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purple)),
        error: (e, _) => Center(
          child: Text('Could not load feed', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (items) {
          // Sync liked IDs from server data on each new load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _syncLikedIds(items));
          });

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Follow friends to see their activity',
                style: GoogleFonts.sora(color: textDim, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }
          return RefreshIndicator(
            color: purple,
            onRefresh: () async => ref.invalidate(socialFeedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final profile = item['profiles'] as Map<String, dynamic>? ?? {};
                final episode = item['episodes'] as Map<String, dynamic>? ?? {};
                final series = item['series'] as Map<String, dynamic>?;
                final serverLikeCount = (item['activity_likes'] as List?)?.length ?? 0;
                final comments = (item['activity_comments'] as List?)?.length ?? 0;
                final eventId = item['id'] as String;
                final isLiked = _likedIds.contains(eventId);
                final serverLiked = _serverLikedIds.contains(eventId);
                final avatarUrl = profile['avatar_url'] as String?;
                final username = profile['username'] as String? ?? 'Unknown';
                final rawDate = item['created_at'] as String?;

                // Optimistic like count: adjust from server count based on UI vs server state
                final displayLikes = serverLikeCount +
                    (isLiked && !serverLiked ? 1 : 0) -
                    (!isLiked && serverLiked ? 1 : 0);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: card,
                        child: avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                                    style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                            : Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.nunito(fontSize: 14),
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => context.push('/fan/${item['user_id']}'),
                                      child: Text(
                                        username,
                                        style: GoogleFonts.nunito(
                                          color: textCol,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' watched ',
                                    style: TextStyle(color: textSec),
                                  ),
                                  TextSpan(
                                    text: episode['title'] as String? ?? '',
                                    style: const TextStyle(
                                      color: textCol,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (series != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                series['title'] as String? ?? '',
                                style: GoogleFonts.sora(color: textDim, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      if (isLiked) {
                                        _likedIds.remove(eventId);
                                      } else {
                                        _likedIds.add(eventId);
                                      }
                                    });
                                    await ref.read(socialRepositoryProvider)
                                        .toggleLike(eventId, isLiked);
                                    ref.invalidate(socialFeedProvider);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? pink : textDim,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$displayLikes',
                                        style: GoogleFonts.sora(color: textDim, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.chat_bubble_outline, color: textDim, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$comments',
                                  style: GoogleFonts.sora(color: textDim, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  rawDate != null ? _timeAgo(rawDate) : '',
                                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
