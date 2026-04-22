import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';

class CurrencyDisplay extends StatefulWidget {
  final int amount;
  final String emoji;
  final Color color;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    required this.emoji,
    required this.color,
  });

  @override
  State<CurrencyDisplay> createState() => _CurrencyDisplayState();
}

class _CurrencyDisplayState extends State<CurrencyDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _deltaOpacity;
  late Animation<Offset> _deltaSlide;

  int _displayed = 0;
  int _delta = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.amount;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _deltaOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);
    _deltaSlide = Tween(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.2),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant CurrencyDisplay old) {
    super.didUpdateWidget(old);
    if (widget.amount != old.amount) {
      _delta = widget.amount - _displayed;
      _displayed = widget.amount;
      if (_delta != 0) {
        _ctrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Text(
            '${widget.emoji} $_displayed',
            style: GoogleFonts.nunito(
              color: widget.color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        if (_delta != 0)
          Positioned(
            top: -4,
            right: -4,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => SlideTransition(
                position: _deltaSlide,
                child: Opacity(
                  opacity: _deltaOpacity.value,
                  child: Text(
                    _delta > 0 ? '+$_delta' : '$_delta',
                    style: GoogleFonts.nunito(
                      color: _delta > 0 ? green : pink,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
