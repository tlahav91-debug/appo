import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/album_provider.dart';
import 'collectible_card.dart';

class AlbumScreen extends ConsumerWidget {
  final String seriesId;

  const AlbumScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumProvider(seriesId));
    final collectiblesAsync = ref.watch(seriesCollectiblesProvider(seriesId));
    final ownedAsync = ref.watch(ownedCollectibleIdsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: collectiblesAsync.when(
        data: (collectibles) {
          final owned = ownedAsync.valueOrNull ?? {};
          final ownedCount = collectibles.where((c) => owned.contains(c.id)).length;
          final total = albumAsync.valueOrNull?.totalCards ?? collectibles.length;
          final albumName = albumAsync.valueOrNull?.name ?? 'Album';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumName,
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? ownedCount / total : 0,
                                minHeight: 8,
                                backgroundColor: surface,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(purple),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$ownedCount / $total',
                            style: GoogleFonts.nunito(
                              color: textSec,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => CollectibleCard(
                      collectible: collectibles[i],
                      owned: owned.contains(collectibles[i].id),
                    ),
                    childCount: collectibles.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: pink)),
        error: (e, _) => Center(
          child: Text('Failed to load album',
              style: GoogleFonts.sora(color: textSec)),
        ),
      ),
    );
  }
}
