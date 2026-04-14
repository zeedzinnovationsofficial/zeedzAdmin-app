import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          /// ✅ Border
          border: Border.all(
            color: const Color.fromARGB(255, 222, 221, 221),
            width: 1,
          ),

          /// ✨ Shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        /// ✅ EVERYTHING INSIDE CARD
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔷 TITLE (NOW INSIDE)
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 10),

            /// 🔷 CONTENT (Pie / Bar Chart)
            child,
          ],
        ),
      ),
    );
  }
}