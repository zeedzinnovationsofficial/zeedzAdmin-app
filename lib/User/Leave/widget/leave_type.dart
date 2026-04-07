import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/Leave/widget/leave_type_card.dart';

class LeaveType extends StatefulWidget {
  const LeaveType({super.key});

  @override
  State<LeaveType> createState() => _LeaveTypeState();
}

class _LeaveTypeState extends State<LeaveType> {
  String selectedType = "personal";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Row(
      children: [
        SizedBox(width: size.width * 0.03),

        LeaveTypeCard(
          title: "Personal",
         
          isSelected: selectedType == "personal",
          onTap: () {
            setState(() {
              selectedType = "personal";
            });
          },
        ),

        SizedBox(width: size.width * 0.02),

        LeaveTypeCard(
          title: "Sick",
          
          isSelected: selectedType == "sick",
          onTap: () {
            setState(() {
              selectedType = "sick";
            });
          },
        ),
      ],
    );
  }
}
