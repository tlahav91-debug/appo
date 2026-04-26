import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';

class MetaPlaceholderScreen extends StatelessWidget {
  const MetaPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('💎 Meta World', style: GoogleFonts.nunito(color: gold, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Your world is coming soon', style: GoogleFonts.sora(color: textDim, fontSize: 14)),
        ]),
      ),
    );
  }
}
