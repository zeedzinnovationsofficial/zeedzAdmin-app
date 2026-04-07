import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class LeaveTypeCard extends StatelessWidget {
  final String title;

  final bool isSelected;
  final VoidCallback onTap;

  const LeaveTypeCard({
    super.key,
    required this.title,

    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        height: size.height * 0.1,
        width: size.width * 0.46,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalblue : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
