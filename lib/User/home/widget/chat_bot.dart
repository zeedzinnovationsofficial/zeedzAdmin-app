import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeedz_attendance/User/home/widget/chat_page.dart';

class DraggableChatHead extends StatefulWidget {
  const DraggableChatHead({super.key});

  @override
  State<DraggableChatHead> createState() => _DraggableChatHeadState();
}

class _DraggableChatHeadState extends State<DraggableChatHead>
    with SingleTickerProviderStateMixin {
  Offset position = const Offset(300, 500);
  Offset velocity = Offset.zero;

  late AnimationController _controller;

  final double sizeBall = 60;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePosition);
  }

  void _updatePosition() {
    final screen = MediaQuery.of(context).size;

    setState(() {
      // move
      position += velocity;

      // friction (slow down gradually)
      velocity *= 0.985;

      // WALL BOUNCE

      // LEFT
      if (position.dx <= 0) {
        position = Offset(0, position.dy);
        velocity = Offset(-velocity.dx * 0.8, velocity.dy);
      }

      // RIGHT
      if (position.dx >= screen.width - sizeBall) {
        position = Offset(screen.width - sizeBall, position.dy);
        velocity = Offset(-velocity.dx * 0.8, velocity.dy);
      }

      // TOP
      if (position.dy <= 0) {
        position = Offset(position.dx, 0);
        velocity = Offset(velocity.dx, -velocity.dy * 0.8);
      }

      // BOTTOM
      if (position.dy >= screen.height - 120) {
        position = Offset(position.dx, screen.height - 120);
        velocity = Offset(velocity.dx, -velocity.dy * 0.7);
      }

      // STOP + EDGE SNAP
      if (velocity.distance < 0.6) {
        velocity = Offset.zero;
        _controller.stop();

        _snapToEdge();

        HapticFeedback.lightImpact();
      }
    });
  }

  void _snapToEdge() {
    final screen = MediaQuery.of(context).size;

    double middle = screen.width / 2;

    setState(() {
      if (position.dx < middle) {
        // snap LEFT
        position = Offset(0, position.dy);
      } else {
        // snap RIGHT
        position = Offset(screen.width - sizeBall, position.dy);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _controller.stop();
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;

            // stronger drag tracking
            velocity = details.delta * 3;
          });
        },
        onPanEnd: (details) {
          // STRONG THROW
          velocity = details.velocity.pixelsPerSecond * 0.004;

          _controller.repeat();
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage()),
          );
        },
        child: Container(
          width: sizeBall,
          height: sizeBall,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            boxShadow: [
              BoxShadow(blurRadius: 15, spreadRadius: 2, color: Colors.black26),
            ],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
