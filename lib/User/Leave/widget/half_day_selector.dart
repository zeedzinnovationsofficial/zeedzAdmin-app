import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/Leave/widget/small_check_option.dart';

class HalfDaySelector extends StatefulWidget {
  const HalfDaySelector({super.key});

  @override
  State<HalfDaySelector> createState() => _HalfDaySelectorState();
}

class _HalfDaySelectorState extends State<HalfDaySelector> {
  String selectedOption = "none";
  // values: "first", "second"

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(width: size.width * 0.03),
          SmallCheckOption(
            label: "Half Day",
            isSelected: selectedOption == "first",
            onTap: () {
              setState(() {
                selectedOption = "first";
              });
            },
          ),

          SizedBox(width: size.width * 0.28),

          SmallCheckOption(
            label: "Half Day",
            isSelected: selectedOption == "second",
            onTap: () {
              setState(() {
                selectedOption = "second";
              });
            },
          ),
        ],
      ),
    );
  }
}
