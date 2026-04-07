import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/attendance/widget/leave_history.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';
import 'package:zeedz_attendance/User/home/attendance/widget/months.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.01),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: punch.profileImageUrl.isNotEmpty
                        ? NetworkImage(punch.profileImageUrl)
                        : null,
                    child: punch.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),

                  SizedBox(width: size.width * 0.02),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        punch.name.isEmpty ? "Enter Name" : punch.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: ${punch.employeeId ?? ''}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              const Center(
                child: Text(
                  "Attendance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              const Months(),

              SizedBox(height: size.height * 0.02),
              Text("Attendance"),

              // const DatePicker(),
              SizedBox(height: size.height * 0.02),

              //  Summary Row 1
              SummaryRow(
                leftCard: SummaryCard(
                  value: punch.presentDays.toString(),
                  title: "Present",
                  valueColor: Colors.green,
                ),
                rightCard: SummaryCard(
                  value: punch.absentDays.toString(),
                  title: "Absent",
                  valueColor: Colors.red,
                ),
              ),

              SizedBox(height: size.height * 0.01),

              //  Summary Row 2
              SummaryRow(
                leftCard: SummaryCard(
                  value: punch.leaveDays.toString(),
                  title: "Leave",
                  valueColor: Colors.orange,
                ),
                rightCard: SummaryCard(
                  value: punch.formattedTotalHours,
                  title: "Hours",
                  valueColor: Colors.blue,
                ),
              ),

              SizedBox(height: size.height * 0.01),

              Center(
                child: const Text(
                  "Recent Records",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: size.height * 0.01),

              Expanded(
                child: Consumer<PunchProvider>(
                  builder: (context, provider, child) {
                    return ListView.builder(
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        DateTime date = DateTime.now().subtract(
                          Duration(days: index),
                        );

                        // Find matching DB record
                        final record = provider.attendanceList.firstWhere((
                          item,
                        ) {
                          final itemDate = DateTime.parse(item['date']);
                          return itemDate.year == date.year &&
                              itemDate.month == date.month &&
                              itemDate.day == date.day;
                        }, orElse: () => {});

                        DateTime? punchIn;
                        DateTime? punchOut;

                        if (record.isNotEmpty) {
                          if (record['punch_in'] != null) {
                            punchIn = DateTime.parse(record['punch_in']);
                          }

                          if (record['punch_out'] != null) {
                            punchOut = DateTime.parse(record['punch_out']);
                          }
                        }

                        return LeaveHistory(
                          date: date,
                          punchIn: punchIn,
                          punchOut: punchOut, status: '',
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
