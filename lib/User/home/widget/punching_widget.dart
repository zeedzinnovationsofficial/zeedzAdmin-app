import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class PunchingWidget extends StatelessWidget {
  final String punchStatus;
  final VoidCallback onTap;
  final bool isLoading;

  const PunchingWidget({
    super.key,
    required this.punchStatus,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isPunchIn = punchStatus == "in";

    // ✅ 1. LOADER FIRST (highest priority)
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: size.height * 0.06,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // ❌ 2. hide ONLY when truly completed
    if (punchStatus == "done") {
      return const SizedBox();
    }

   return Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: (punchStatus == "done" || isLoading) ? null : onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: size.height * 0.06,
      width: double.infinity,
      decoration: BoxDecoration(
        color: punchStatus == "done"
            ? Colors.grey
            : isPunchIn
                ? AppColors.green
                : AppColors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          punchStatus == "done"
              ? "Completed"
              : isPunchIn
                  ? "Punch In"
                  : "Punch Out",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
);
}
}
