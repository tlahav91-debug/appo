import 'package:flutter/material.dart';

class GBtn extends StatefulWidget {
  final LinearGradient gradient;
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const GBtn({
    super.key,
    required this.gradient,
    required this.child,
    this.onPressed,
    this.width,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<GBtn> createState() => _GBtnState();
}

class _GBtnState extends State<GBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _shadowColor {
    final endColor = widget.gradient.colors.last;
    return endColor.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
