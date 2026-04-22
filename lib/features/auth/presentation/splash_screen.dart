import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          Stars(),
          Center(
            child: Text(
              'DramaPlay',
              style: TextStyle(
                color: pink,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 36,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
