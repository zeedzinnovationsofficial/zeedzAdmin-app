import 'package:flutter/material.dart';

class AttendanceChartSkeleton extends StatelessWidget {
  const AttendanceChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 18,
            width: 160,
            decoration: _box(),
          ),
          const SizedBox(height: 30),

          // Circle skeleton (chart)
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (_) => Container(
                height: 12,
                width: 60,
                decoration: _box(),
              ),
            ),
          )
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(6),
    );
  }
}