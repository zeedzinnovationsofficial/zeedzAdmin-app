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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final provider = context.read<PunchProvider>();

    setState(() {
      isLoading = true;
    });

      await provider.fetchLeaveList();

    setState(() {
      isLoading = false;
    });
  }

  Widget skeletonBox({double height = 20, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.05),

              skeletonBox(height: 30, width: 200), // title
              SizedBox(height: 20),

              skeletonBox(height: 50), // leave type
              skeletonBox(height: 50), // date picker
              skeletonBox(height: 50), // half day
              skeletonBox(height: 50), // total days
              skeletonBox(height: 80), // reason
              skeletonBox(height: 50), // submit
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              const Padding(padding: EdgeInsets.all(12)),

              Row(
                children: [
                  if (punch.role == 'hr' ||
                      punch.role == 'admin' ||
                      punch.role == 'superadmin')
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 48),

                  SizedBox(width: size.width * 0.2),
                  const Text(
                    "Leave Application",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.018),
              const Text("Leave Type"),
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
