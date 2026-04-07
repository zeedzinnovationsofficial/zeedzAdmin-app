import 'package:flutter/material.dart';

class WorkdayLoader extends StatefulWidget {
  const WorkdayLoader({super.key});

  @override
  State<WorkdayLoader> createState() => _WorkdayLoaderState();
}

class _WorkdayLoaderState extends State<WorkdayLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sunRise;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _sunRise = Tween<double>(begin: 40, end: -20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Office Building
                  const Icon(
                    Icons.business,
                    size: 100,
                    color: Colors.blueGrey,
                  ),

                  // Rising Sun
                  AnimatedBuilder(
                    animation: _sunRise,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _sunRise.value),
                        child: const Icon(
                          Icons.wb_sunny,
                          size: 40,
                          color: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Starting your workday...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Preparing attendance dashboard",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}