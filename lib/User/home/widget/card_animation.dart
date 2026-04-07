import 'package:flutter/material.dart';

class ZoomTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ZoomTapCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<ZoomTapCard> createState() => _ZoomTapCardState();
}

class _ZoomTapCardState extends State<ZoomTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
    );

    scale = controller;
    controller.value = 1.0;
  }

  void _onTapDown(TapDownDetails details) {
    controller.reverse(); // 🔽 shrink
  }

  void _onTapUp(TapUpDetails details) {
    controller.forward(); // 🔼 back to normal
    widget.onTap?.call();
  }

  void _onTapCancel() {
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}