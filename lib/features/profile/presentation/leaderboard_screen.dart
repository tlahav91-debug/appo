import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: const Stack(
        children: [
          Stars(),
          Center(
            child: Text(
              'Rank',
              style: TextStyle(
                color: textCol,
                fontFamily: 'Nunito',
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
