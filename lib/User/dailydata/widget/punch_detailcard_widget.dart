import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class PunchDetailcardWidget extends StatelessWidget {
  final IconData icon;
  final Color circleColor;
  final Color iconColor;
  final String title;
  final String time;
  final String location;

  const PunchDetailcardWidget({
    super.key,
    required this.icon,
    required this.circleColor,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: size.height * 0.22,
        width: size.width * 0.42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
        ),
        child: Column(
          children: [
            Container(
              height: size.height * 0.07,
              width: size.width * 0.7,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),

            SizedBox(height: size.height * 0.01),

            Text(title),

            SizedBox(height: size.height * 0.01),

            Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),

            SizedBox(height: size.height * 0.01),

            Text(location, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
