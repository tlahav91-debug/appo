import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../../shared/widgets/stars.dart';
import '../../events/application/lava_quest_provider.dart';
import '../../events/presentation/lava_quest_card.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(activeQuestsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          questsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: lava),
            ),
            error: (e, _) => Center(
              child: Text(
                'Failed to load events',
                style: GoogleFonts.sora(color: textDim),
              ),
            ),
            data: (quests) {
              if (quests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'No active quests right now',
                        style: GoogleFonts.nunito(
                          color: textSec,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check back soon for new Lava Quests',
                        style: GoogleFonts.sora(color: textDim, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: quests.length,
                itemBuilder: (context, i) => LavaQuestCard(quest: quests[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}
