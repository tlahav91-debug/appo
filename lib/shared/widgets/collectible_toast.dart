import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';

class CollectibleToast {
  static void show(BuildContext context, String name) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CollectibleToastWidget(
        name: name,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _CollectibleToastWidget extends StatefulWidget {
  final String name;
  final VoidCallback onDone;

  const _CollectibleToastWidget({required this.name, required this.onDone});

  @override
  State<_CollectibleToastWidget> createState() => _CollectibleToastWidgetState();
}

class _CollectibleToastWidgetState extends State<_CollectibleToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _slide = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.4))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 27,
      ),
    ]).animate(_ctrl);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => SlideTransition(
            position: _slide,
            child: Opacity(
              opacity: _opacity.value,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: purpleGrad,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🃏', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${widget.name} Collected!',
                          style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
