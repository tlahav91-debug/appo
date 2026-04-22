import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
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
    );
  }
}
