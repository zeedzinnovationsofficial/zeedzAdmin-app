import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/date_picker.dart';
import 'package:zeedz_attendance/User/Leave/widget/half_day_selector.dart';
import 'package:zeedz_attendance/User/Leave/widget/leave_total_days.dart';
import 'package:zeedz_attendance/User/Leave/widget/leave_type.dart';
import 'package:zeedz_attendance/User/Leave/widget/reason.dart';
import 'package:zeedz_attendance/User/Leave/widget/submit_button.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  @override
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<PunchProvider>();

          // reload needed data
          await provider.initializeApp(); // or specific function if you have
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              Padding(padding: EdgeInsets.all(12)),

              Row(
                children: [
                  if (punch.role == 'hr' ||
                      punch.role == 'admin' ||
                      punch.role == 'superadmin') //  Show only HR
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  else
                    const SizedBox(width: 48),
                  SizedBox(width: size.width * 0.2),
                  const Text(
                    "Leave Application",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.018),
              Text("Leave Type"),
              SizedBox(height: size.height * 0.018),
              const LeaveType(),
              SizedBox(height: size.height * 0.018),
              const DatePicker(),

              SizedBox(height: size.height * 0.018),
              const HalfDaySelector(),

              SizedBox(height: size.height * 0.018),
              const LeaveTotalDays(),
              SizedBox(height: size.height * 0.018),
              const Reason(),
              SizedBox(height: size.height * 0.018),
              const SubmitButton(),
              SizedBox(height: size.height * 0.6),
            ],
          ),
        ),
      ),
    );
  }
}
