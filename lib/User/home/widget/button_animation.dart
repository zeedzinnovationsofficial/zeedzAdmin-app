import 'package:flutter/material.dart';

class BounceTapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceTapWrapper({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BounceTapWrapper> createState() => _BounceTapWrapperState();
}

class _BounceTapWrapperState extends State<BounceTapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(controller);
  }

  Future<void> _handleTap() async {
    await controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}