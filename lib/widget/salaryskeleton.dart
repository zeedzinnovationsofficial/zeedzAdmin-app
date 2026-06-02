import 'package:flutter/material.dart';

class SalarySkeleton extends StatelessWidget {
  const SalarySkeleton({super.key});

  Widget box({double? height, double? width}) {
    return Container(
      height: height ?? 20,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// Salary card skeleton
          Container(
            height: size.height * 0.18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          SizedBox(height: size.height * 0.02),

          /// small cards
          Row(
            children: [
              Expanded(child: box(height: 60)),
              SizedBox(width: 10),
              Expanded(child: box(height: 60)),
            ],
          ),

          SizedBox(height: size.height * 0.02),

          /// chart skeletons
          box(height: size.height * 0.19),
          SizedBox(height: 12),
          box(height: size.height * 0.19),

          SizedBox(height: 12),

          /// recent list skeleton
          Column(
            children: List.generate(1, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.grey.shade300),
                    SizedBox(width: 10),
                    Expanded(child: box(height: 40)),
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}