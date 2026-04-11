import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zeedz_attendance/User/attendance/widget/leave_history.dart';
import 'package:zeedz_attendance/User/attendance/widget/months.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTimeRange? selectedRange;
  int selectedMonth = DateTime.now().month;
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> leaveList = [];

  int itemsLoaded = 15;
  final int loadMore = 15;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAttendance();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          itemsLoaded += loadMore;
        });
      }
    });
  }

  bool isWorkingDay(DateTime d) {
    final sch = context.read<PunchProvider>().workSchedule?.toLowerCase();

    if (sch == "mon_fri") {
      return d.weekday >= DateTime.monday && d.weekday <= DateTime.friday;
    } else if (sch == "mon_sat") {
      return d.weekday != DateTime.sunday;
    } else {
      return d.weekday != DateTime.sunday;
    }
  }

  Future<void> loadAttendance() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final attendanceResponse = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .order('date');

    final leaveResponse = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'approved');

    setState(() {
      attendanceList = List<Map<String, dynamic>>.from(attendanceResponse);
      leaveList = List<Map<String, dynamic>>.from(leaveResponse);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<PunchProvider>();

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Attendance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              const Months(),

              SizedBox(height: size.height * 0.02),

              /// EMPLOYEE INFO
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("ID: ${provider.employeeId ?? '--'}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              /// RECENT RECORDS
              const Text(
                "Recent Records",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: size.height * 0.01),

              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: itemsLoaded,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    DateTime date =
                        DateTime.now().subtract(Duration(days: index));

                    final joiningDate =
                        DateTime.parse(provider.joiningDate);

                    if (date.isBefore(joiningDate)) {
                      return const SizedBox();
                    }

                    DateTime? punchIn;
                    DateTime? punchOut;

                    final now = DateTime.now();

                    String status = "not punchin";

                    final dateKey =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                    final todayKey =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                    final record = attendanceList.firstWhere(
                      (item) => item['date'] == dateKey,
                      orElse: () => {},
                    );

                    final leaveRecord = leaveList.firstWhere((leave) {
                      final start = DateTime.parse(leave['start_date'])
                          .toIso8601String()
                          .split('T')[0];

                      final end = DateTime.parse(leave['end_date'])
                          .toIso8601String()
                          .split('T')[0];

                      return dateKey.compareTo(start) >= 0 &&
                          dateKey.compareTo(end) <= 0;
                    }, orElse: () => {});

                    /// 1. LEAVE
                   final isHoliday = provider.isHoliday(date);
                   print("DATE: $date");
print("IS HOLIDAY: ${provider.isHoliday(date)}");

/// ⭐ 0. HOLIDAY MUST BE FIRST (HARD STOP)
if (isHoliday) {
  status = "holiday";
  punchIn = null;
  punchOut = null;
}

/// 1. LEAVE
else if (leaveRecord.isNotEmpty) {
  status = "leave";
}

/// 2. ATTENDANCE
else if (record.isNotEmpty) {
  if (record['status'] == 'approved') {
    status = "present";
  } else if (record['status'] == 'pending') {
    status = "pending";
  } else if (record['status'] == 'absent') {
    status = "absent";
  }

  if (record['punch_in'] != null) {
    punchIn = DateTime.parse(record['punch_in']);
  }

  if (record['punch_out'] != null) {
    punchOut = DateTime.parse(record['punch_out']);
  }
}

/// 3. NO RECORD
else {
  if (dateKey == todayKey) {
    final cutoff = DateTime(now.year, now.month, now.day, 23, 59);

    status = now.isAfter(cutoff) ? "absent" : "not punchin";
  } else if (date.isBefore(now)) {
    status = "absent";
  }
}
                    return LeaveHistory(
                      date: date,
                      punchIn: punchIn,
                      punchOut: punchOut,
                      status: status,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}