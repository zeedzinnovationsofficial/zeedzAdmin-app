import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PunchStatusSkeleton extends StatelessWidget {
  const PunchStatusSkeleton({super.key});

  Widget box({double height = 12, double width = double.infinity}) {
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              /// HEADER
              Row(
                children: [
                  box(height: size.height*0.01, width: 120),
                  const Spacer(),
                  box(height: size.height*0.01, width: 70),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              /// TIME ROW
              Row(
                children: [
                  box(height: size.height*0.01, width: 80),
                  const Spacer(),
                  box(height: size.height*0.01, width: 80),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              /// HOLIDAY / CONTENT BLOCK
              box(height: size.height*0.001, width: double.infinity),
            ],
          ),
        ),
      ),
    );
  }
}