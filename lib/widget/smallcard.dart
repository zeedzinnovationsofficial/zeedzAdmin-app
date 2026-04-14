import 'package:flutter/material.dart';

class SmallCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isGreen;
  final bool isRed;

  const SmallCard({
    super.key,
    required this.title,
    required this.value,
    this.isGreen = false,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),

          /// ✅ Better visible border
          border: Border.all(
            color: const Color.fromARGB(255, 228, 228, 228),
            width: 1,
          ),

          /// ✨ optional shadow (premium look)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGreen
                    ? Colors.green
                    : isRed
                        ? Colors.red
                        : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}