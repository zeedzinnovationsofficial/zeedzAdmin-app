import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LeaveSkeleton extends StatelessWidget {
  const LeaveSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 80),

              Container(height: 20, width: 150, color: Colors.white),

              const SizedBox(height: 20),

              ...List.generate(
                8,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}