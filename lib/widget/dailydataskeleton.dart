import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DailyDataSkeleton extends StatelessWidget {
  const DailyDataSkeleton({super.key});

  Widget box({double height = 20, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.06),

            box(height: 20, width: 120), // Title

            SizedBox(height: size.height * 0.02),

            box(height: 50, width: size.width * 0.9), // Status card

            SizedBox(height: size.height * 0.02),

            box(height: 20, width: 100), // Date

            SizedBox(height: size.height * 0.02),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                box(height: 120, width: size.width * 0.4),
                box(height: 120, width: size.width * 0.4),
              ],
            ),

            SizedBox(height: size.height * 0.02),

            box(height: 20, width: 150), // Leave title

            SizedBox(height: size.height * 0.02),

            box(height: 120, width: size.width * 0.9),
            box(height: 120, width: size.width * 0.9),
          ],
        ),
      ),
    );
  }
}