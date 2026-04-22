import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          const Stars(),
          Center(
            child: Text(
              'DramaPlay',
              style: GoogleFonts.nunito(
                color: pink,
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
