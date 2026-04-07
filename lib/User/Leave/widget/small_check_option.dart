import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class SmallCheckOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SmallCheckOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: size.height * 0.02,
            width: size.width * 0.04,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.royalblue : AppColors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),

          SizedBox(width: size.width * 0.03),

          Text(label),
        ],
      ),
    );
  }
}
