import 'package:flutter/material.dart';
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
    // If day completed → hide button
    if (punchStatus == "done" || punchStatus == "absent") {
      return const SizedBox();
    }

    final bool isPunchIn = punchStatus == "in";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size.height * 0.06,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isPunchIn ? AppColors.green : AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            isPunchIn ? "Punch In" : "Punch Out",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
