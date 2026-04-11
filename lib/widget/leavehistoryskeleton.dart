import 'package:flutter/material.dart';


class LeaveHistorySkeleton extends StatelessWidget {
  const LeaveHistorySkeleton({super.key});

  Widget box({double height = 12, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: size.height * 0.15,
          width: size.width * 0.9,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(width: size.width * 0.6),
              box(width: size.width * 0.8),
              const SizedBox(height: 10),
              box(width: size.width * 0.4),
            ],
          ),
        );
      }),
    );
  }
}