import 'package:flutter/material.dart';
import 'package:zeedz_attendance/widget/summaryrowskeleton.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';


class SummaryRow extends StatelessWidget {
  final SummaryCard leftCard;
  final SummaryCard rightCard;
  final bool isLoading;   // ✅ ADD THIS

  const SummaryRow({
    super.key,
    required this.leftCard,
    required this.rightCard,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔥 SHOW SKELETON HERE
    if (isLoading) {
      return const SummaryRowSkeleton();
    }

    return Row(
      children: [
        SizedBox(width: size.width * 0.05),
        Expanded(child: leftCard),
        SizedBox(width: size.width * 0.02),
        Expanded(child: rightCard),
        SizedBox(width: size.width * 0.05),
      ],
    );
  }
}