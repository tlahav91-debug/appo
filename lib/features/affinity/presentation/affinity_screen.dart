import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/analytics/analytics_provider.dart';
import '../../../core/theme/tokens.dart';
import '../application/affinity_provider.dart';
import 'affinity_card.dart';

class AffinityScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const AffinityScreen({super.key, required this.seriesId});

  @override
  ConsumerState<AffinityScreen> createState() => _AffinityScreenState();
}

class _AffinityScreenState extends ConsumerState<AffinityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).capture('affinity_viewed', properties: {
        'series_id': widget.seriesId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final affinityAsync = ref.watch(characterAffinitiesProvider(widget.seriesId));

    return Scaffold(
      backgroundColor: bgDeep,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bgDeep,
            foregroundColor: textCol,
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3A1A5E), Color(0xFF080612)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      Text(
                        'Characters',
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'Your affinity grows with each choice',
                        style: GoogleFonts.sora(color: textSec, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          affinityAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: purple)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Failed to load characters',
                  style: GoogleFonts.sora(color: textDim),
                ),
              ),
            ),
            data: (affinities) {
              if (affinities.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💙', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'No characters yet',
                          style: GoogleFonts.nunito(
                            color: textSec,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Watch episodes and make choices\nto build relationships',
                          style:
                              GoogleFonts.sora(color: textDim, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort: highest affinity points first
              final sorted = [...affinities]
                ..sort((a, b) => b.affinityPoints.compareTo(a.affinityPoints));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => AffinityCard(affinity: sorted[i]),
                    childCount: sorted.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
