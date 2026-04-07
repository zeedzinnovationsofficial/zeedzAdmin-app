import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
    );

    scale = controller;
    controller.value = 1.0;
  }

  void _tapDown(TapDownDetails details) {
    controller.reverse(); // shrink
  }

  void _tapUp(TapUpDetails details) {
    controller.forward(); // back to normal
    widget.onTap();
  }

  void _tapCancel() {
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      child: ScaleTransition(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}