import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/g_btn.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: Stack(
        children: [
          const Stars(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              // Rankings button
              GBtn(
                gradient: pinkFull,
                onPressed: () => context.push('/leaderboard'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Rankings',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Rewards',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
