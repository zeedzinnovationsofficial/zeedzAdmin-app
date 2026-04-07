import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class Reason extends StatelessWidget {
  const Reason({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reason",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: size.height * 0.01),
        Container(
          padding: EdgeInsets.all(12),
          height: size.height * 0.2,
          width: size.width * 0.90,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightgrey,
                blurRadius: 2,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: SizedBox(
            width: size.width * 0.1,
            child: TextField(
              maxLines: null, // ✅ unlimited lines
              expands: true, // ✅ fill container height
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top, // ✅ start from top
              onChanged: (value) {
                context.read<PunchProvider>().setReason(value);
              },
              decoration: const InputDecoration(
                hintText: "Please provide a reason for leave",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }
}
