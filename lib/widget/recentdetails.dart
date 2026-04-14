import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class RecentRecords extends StatelessWidget {
  final List<Map<String, dynamic>> records; // ✅ ADD THIS

  const RecentRecords({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    /// ✅ HIDE if empty
    if (records.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Details",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: size.height * 0.02),

        /// 🔁 LOOP DATA
        ...records.map((item) {
          return _recordTile(
            icon: item["icon"],
            iconColor: item["iconColor"],
            title: item["title"],
            subtitle: item["subtitle"],
            amount: item["amount"],
            amountColor: item["amountColor"],
          );
        }).toList(),
      ],
    );
  }

  Widget _recordTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600)),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}