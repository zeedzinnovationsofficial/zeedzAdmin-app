import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class LeaveTotalDays extends StatelessWidget {
  const LeaveTotalDays({super.key});

  @override
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.all(9),
      height: size.height * 0.06,
      width: size.width * 0.89,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightgrey,
            blurRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Total Days : ${punch.totalLeaveDays}",
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
