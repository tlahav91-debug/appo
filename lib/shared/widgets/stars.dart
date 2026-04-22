import 'dart:math';
import 'package:flutter/material.dart';

class Stars extends StatefulWidget {
  const Stars({super.key});

  @override
  State<Stars> createState() => _StarsState();
}

class _StarsState extends State<Stars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _stars = List.generate(80, (_) => _Star(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _StarPainter(_stars, _controller.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Star {
  final double x;   // 0..1 normalised
  final double y;   // 0..1 normalised
  final double opacity;
  final double size;

  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        opacity = 0.2 + rng.nextDouble() * 0.6,
        size = 1.0 + rng.nextDouble();
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress; // 0..1

  _StarPainter(this.stars, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in stars) {
      final dy = (s.y - progress * 0.03) % 1.0;
      paint.color = Colors.white.withOpacity(s.opacity);
      canvas.drawCircle(
        Offset(s.x * size.width, dy * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.progress != progress;
}
