import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../profile/application/profile_provider.dart';
import '../application/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Set<String> _selected = {};

  static const _genres = [
    'Romance',
    'Thriller',
    'Comedy',
    'Fantasy',
    'Drama',
    'Mystery',
  ];

  Future<void> _submit() async {
    await completeOnboarding(_selected.toList());
    ref.invalidate(profileProvider);
    if (mounted) context.go('/home');
  }

  Future<void> _skip() async {
    await completeOnboarding([]);
    ref.invalidate(profileProvider);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          const Stars(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'What do you love watching? 🎬',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pick your genres to personalise your feed',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: textSec,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _genres
                        .map(
                          (genre) => _GenrePill(
                            genre: genre,
                            selected: _selected.contains(genre),
                            onTap: () {
                              setState(() {
                                if (_selected.contains(genre)) {
                                  _selected.remove(genre);
                                } else {
                                  _selected.add(genre);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: hasSelection ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: hasSelection ? purpleGrad : null,
                        color: hasSelection ? null : surface,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Let's Go",
                        style: GoogleFonts.nunito(
                          color: hasSelection ? textCol : textDim,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.sora(
                        color: textSec,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OnboardingGenreSheet — bottom sheet shown after first choice
// ---------------------------------------------------------------------------

class OnboardingGenreSheet extends ConsumerStatefulWidget {
  const OnboardingGenreSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => const OnboardingGenreSheet(),
    );
  }

  @override
  ConsumerState<OnboardingGenreSheet> createState() => _OnboardingGenreSheetState();
}

class _OnboardingGenreSheetState extends ConsumerState<OnboardingGenreSheet> {
  Set<String> _selected = {};

  static const _genres = ['Romance', 'Thriller', 'Comedy', 'Fantasy', 'Drama', 'Mystery'];

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    await completeOnboarding(_selected.toList());
    ref.invalidate(profileProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderHi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Find more like this',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick the genres you love',
            style: GoogleFonts.sora(color: textDim, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _genres
                .map(
                  (g) => _GenrePill(
                    genre: g,
                    selected: _selected.contains(g),
                    onTap: () => setState(() {
                      _selected.contains(g)
                          ? _selected.remove(g)
                          : _selected.add(g);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _selected.isNotEmpty ? _submit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _selected.isNotEmpty ? purpleGrad : null,
                color: _selected.isNotEmpty ? null : surface,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: Text(
                "Let's Go",
                style: GoogleFonts.nunito(
                  color: _selected.isNotEmpty ? textCol : textDim,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Genre Pill
// ---------------------------------------------------------------------------

class _GenrePill extends StatelessWidget {
  final String genre;
  final bool selected;
  final VoidCallback onTap;

  const _GenrePill({
    required this.genre,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? purpleGrad : null,
          color: selected ? null : surface,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? null
              : Border.all(color: border),
        ),
        child: Text(
          genre,
          style: GoogleFonts.nunito(
            color: selected ? textCol : textSec,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
