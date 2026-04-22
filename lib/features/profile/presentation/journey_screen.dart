import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/hud.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

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
              'Journey',
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
