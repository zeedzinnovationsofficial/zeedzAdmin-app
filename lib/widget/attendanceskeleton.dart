import 'package:flutter/material.dart';

class AttendanceSkeleton extends StatelessWidget {
  const AttendanceSkeleton({super.key});

  Widget _box({double? width, double height = 14}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: size.width * 0.4, height: 16),
              const SizedBox(height: 10),
              _box(width: size.width * 0.7),
              const SizedBox(height: 8),
              _box(width: size.width * 0.5),
              const SizedBox(height: 8),
              _box(width: size.width * 0.6),
            ],
          ),
        );
      },
    );
  }
}