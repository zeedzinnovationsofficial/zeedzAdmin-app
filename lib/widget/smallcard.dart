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
    IconData? icon;
    Color valueColor = Colors.black;

    if (isGreen) {
      icon = Icons.trending_up;
      valueColor = Colors.green;
    } else if (isRed) {
      icon = Icons.trending_down;
      valueColor = Colors.red;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(255, 228, 228, 228),
            width: 1,
          ),
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

            /// 🔥 VALUE + ICON ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: valueColor, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}