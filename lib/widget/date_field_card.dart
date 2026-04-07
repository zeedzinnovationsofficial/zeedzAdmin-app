import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class DateFieldCard extends StatelessWidget {
  final String title;
  final String hintText;

  const DateFieldCard({super.key, required this.title, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    DateTime? selectedDate = title == "Start Date"
        ? punch.startDate
        : punch.endDate;

    String displayText = selectedDate != null
        ? DateFormat("MMM dd yyyy").format(selectedDate)
        : hintText;

    return GestureDetector(
      onTap: () async {
        final punch = context.read<PunchProvider>();

        DateTime now = DateTime.now();

        /// 🔥 INITIAL DATE FIX
        DateTime initialDate = title == "End Date" && punch.startDate != null
            ? punch.startDate!
            : now;

        /// 🔥 FIRST DATE FIX
        DateTime firstDate = title == "End Date"
            ? (punch.startDate ?? now) // ✅ fallback to today
            : now; // ✅ start date = today

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          if (title == "Start Date") {
            punch.setStartDate(pickedDate);

            /// 🔥 RESET END DATE IF INVALID
            if (punch.endDate != null && punch.endDate!.isBefore(pickedDate)) {
              punch.setEndDate(pickedDate);
            }
          } else {
            punch.setEndDate(pickedDate);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(height: size.height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: selectedDate != null ? AppColors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
