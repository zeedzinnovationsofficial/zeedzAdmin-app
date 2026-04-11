import 'package:flutter/material.dart';

class SkeletonEmployeeList extends StatelessWidget {
  const SkeletonEmployeeList({super.key});

  Widget box({double height = 20, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                /// avatar
                Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                /// text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(height: 14, width: 120),
                      box(height: 12, width: 80),
                      box(height: 10, width: 60),
                    ],
                  ),
                ),

                /// menu
                Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}