import 'package:flutter/material.dart';
import 'package:zeedz_attendance/widget/date_field_card.dart';

class DatePicker extends StatelessWidget {
  const DatePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: DateFieldCard(title: "Start Date", hintText: "MM DD YYYY"),
          ),

          SizedBox(width: size.width * 0.03),

          Expanded(
            child: DateFieldCard(title: "End Date", hintText: "MM DD YYYY"),
          ),
        ],
      ),
    );
  }
}
