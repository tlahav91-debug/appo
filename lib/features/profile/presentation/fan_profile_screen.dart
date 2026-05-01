import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/fan_profile_provider.dart';

class FanProfileScreen extends ConsumerWidget {
  final String userId;

  const FanProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fanProfileProvider(userId));

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: const BackButton(color: textCol),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pink)),
        error: (_, __) => Center(
          child: Text('Profile not found', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (data) {
          final profile = data['profile'] as Map<String, dynamic>;
          final collectibles = data['collectibles'] as List<dynamic>;
          final follows = data['follows'] as List<dynamic>;
          final checkIns = data['check_ins'] as List<dynamic>;

          final username = profile['username'] as String? ?? 'Anonymous';
          final avatarUrl = profile['avatar_url'] as String?;
          final fanLevel = (profile['fan_level'] as num?)?.toInt() ?? 1;
          final xp = (profile['xp'] as num?)?.toInt() ?? 0;
          final streak = _computeStreak(checkIns);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: surface,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, color: textDim, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: goldGrad,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level $fanLevel',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(icon: '🔥', value: '$streak', label: 'Streak'),
                    const SizedBox(width: 24),
                    _StatChip(icon: '⭐', value: '$fanLevel', label: 'Level'),
                    const SizedBox(width: 24),
                    _StatChip(icon: '✨', value: '$xp', label: 'XP'),
                  ],
                ),
                if (follows.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Following', style: GoogleFonts.sora(color: textSec, fontSize: 12)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: follows.length,
                            itemBuilder: (context, i) {
                              final follow = follows[i] as Map<String, dynamic>;
                              final creatorProfile =
                                  follow['creator_profiles'] as Map<String, dynamic>?;
                              final displayName =
                                  creatorProfile?['display_name'] as String? ?? '';
                              final initials = displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?';
                              return Padding(
                                padding: EdgeInsets.only(right: 12, left: i == 0 ? 0 : 0),
                                child: GestureDetector(
                                  onTap: () => context
                                      .push('/creator/${follow['creator_id']}'),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: surface,
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.nunito(
                                            color: textCol,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.sora(
                                            color: textDim,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (collectibles.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collectibles',
                            style: GoogleFonts.sora(color: textSec, fontSize: 12)),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: collectibles.length,
                          itemBuilder: (context, i) {
                            final row =
                                collectibles[i] as Map<String, dynamic>;
                            final c =
                                row['collectibles'] as Map<String, dynamic>?;
                            if (c == null) return const SizedBox.shrink();
                            return _CollectibleTile(
                              name: c['name'] as String? ?? '',
                              imageUrl: c['image_url'] as String?,
                              rarity: c['rarity'] as String? ?? '',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static int _computeStreak(List<dynamic> checkIns) {
    if (checkIns.isEmpty) return 0;
    final dates = checkIns
        .map((c) => DateTime.parse(c['checked_in_at'] as String).toLocal())
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    if (dates.first != todayDate && dates.first != yesterdayDate) return 0;
    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        Text(
          value,
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        Text(label, style: GoogleFonts.sora(color: textDim, fontSize: 10)),
      ],
    );
  }
}

class _CollectibleTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String rarity;

  const _CollectibleTile({
    required this.name,
    required this.imageUrl,
    required this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rarityColor(rarity), width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.auto_awesome,
                        color: textDim,
                      ))
                  : const Icon(Icons.auto_awesome, color: textDim),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              name,
              style: GoogleFonts.sora(color: textDim, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFFFB800);
      case 'epic':
        return const Color(0xFF9D4EDD);
      case 'rare':
        return const Color(0xFF00C8FF);
      default:
        return borderHi;
    }
  }
}
