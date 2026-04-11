import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SummaryRowSkeleton extends StatelessWidget {
  const SummaryRowSkeleton({super.key});

  Widget box({double height = 12, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget cardSkeleton(double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(height: 14, width: width * 0.5),
          const SizedBox(height: 10),
          box(height: 40, width: width),
          const SizedBox(height: 10),
          box(height: 14, width: width * 0.7),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          children: [
            Expanded(child: cardSkeleton(size.width * 0.4)),
            SizedBox(width: size.width * 0.02),
            Expanded(child: cardSkeleton(size.width * 0.4)),
          ],
        ),
      ),
    );
  }
}