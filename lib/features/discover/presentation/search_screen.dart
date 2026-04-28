import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../application/discover_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = val;
    });
  }

  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textCol, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search field ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.sora(color: textCol, fontSize: 14),
              onChanged: _onChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: gold, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.search, color: textDim),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: textDim, size: 18),
                        onPressed: _clearQuery,
                      )
                    : null,
                hintText: 'Search series or creators…',
                hintStyle: GoogleFonts.sora(color: textDim, fontSize: 14),
              ),
            ),
          ),

          // ── Results ──────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(query, resultsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String query, AsyncValue<SearchResult> resultsAsync) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, color: textDim, size: 56),
            const SizedBox(height: 16),
            Text(
              'Search for series or creators',
              style: GoogleFonts.sora(color: textSec, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: gold),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: GoogleFonts.sora(color: textDim, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
      data: (results) {
        final hasSeries = results.series.isNotEmpty;
        final hasCreators = results.creators.isNotEmpty;

        if (!hasSeries && !hasCreators) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, color: textDim, size: 56),
                const SizedBox(height: 16),
                Text(
                  'No results for "${query.trim()}"',
                  style: GoogleFonts.nunito(
                    color: textSec,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        final items = <Widget>[];

        if (hasSeries) {
          items.add(_SectionHeader(label: 'Series'));
          items.addAll(results.series.map((s) => _SeriesTile(series: s)));
        }

        if (hasCreators) {
          items.add(_SectionHeader(label: 'Creators'));
          items.addAll(
            results.creators.map((c) => _CreatorTile(creator: c)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: gold,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Series tile ────────────────────────────────────────────────────────────────

class _SeriesTile extends StatelessWidget {
  final DiscoverSeries series;
  const _SeriesTile({required this.series});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/series/${series.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: series.coverUrl != null
                      ? Image.network(
                          series.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverPlaceholder(),
                        )
                      : _coverPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (series.genre != null) ...[
                          _GenreChip(label: series.genre!),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${series.totalEpisodes} ep',
                          style: GoogleFonts.sora(
                            color: textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (series.isVip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: goldGrad,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VIP',
                    style: GoogleFonts.nunito(
                      color: bgDeep,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: card,
      child: const Icon(Icons.movie_outlined, color: textDim, size: 24),
    );
  }
}

// ── Genre chip ─────────────────────────────────────────────────────────────────

class _GenreChip extends StatelessWidget {
  final String label;
  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cardHi,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(color: textSec, fontSize: 10),
      ),
    );
  }
}

// ── Creator tile ───────────────────────────────────────────────────────────────

class _CreatorTile extends StatelessWidget {
  final Map<String, dynamic> creator;
  const _CreatorTile({required this.creator});

  @override
  Widget build(BuildContext context) {
    final id = creator['id'] as String? ?? '';
    final displayName = creator['display_name'] as String? ?? 'Unknown';
    final avatarUrl = creator['avatar_url'] as String?;
    final followerCount = (creator['follower_count'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: card,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$followerCount followers',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          // View button
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: cardHi,
              foregroundColor: gold,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => context.push('/creator/$id'),
            child: Text(
              'View',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
