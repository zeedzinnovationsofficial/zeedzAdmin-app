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
import 'package:zeedz_attendance/widget/attendanceskeleton.dart';
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

  // ---------------- WORKING DAY ----------------
  bool isWorkingDay(DateTime d, String? schedule) {
    final sch = schedule?.toLowerCase();

    if (sch == "mon_fri") {
      return d.weekday >= DateTime.monday && d.weekday <= DateTime.friday;
    } else if (sch == "mon_sat") {
      return d.weekday != DateTime.sunday;
    } else {
      return d.weekday != DateTime.sunday;
    }
  }

  // ---------------- LOAD DATA ----------------
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

  // ---------------- SUMMARY ----------------
  Map<String, int> calculateSummary() {
    final provider = context.read<PunchProvider>();

    final joiningDate = DateTime.parse(provider.joiningDate);
    final schedule = provider.workSchedule;

    int present = 0;
    int pending = 0;
    int leave = 0;
    int absent = 0;

    final now = DateTime.now();
    final start = joiningDate;

    final end = DateTime(now.year, selectedMonth, now.day);

    for (final record in attendanceList) {
      final recordDate = DateTime.parse(record['date']);

      if (recordDate.month != selectedMonth) continue;
      if (recordDate.isBefore(start)) continue;
      if (selectedMonth == now.month && recordDate.isAfter(now)) continue;
      
      if (!isWorkingDay(recordDate, schedule)) continue;

      final status = record['status'];

      if (status == 'approved') {
        present++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'absent') {
        absent++;
      }
    }

    for (final leaveItem in leaveList) {
      final startDate = DateTime.parse(leaveItem['start_date']);
      final endDate = DateTime.parse(leaveItem['end_date']);

      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month != selectedMonth) continue;
        if (!isWorkingDay(d, schedule)) continue;
        leave++;
      }
    }

    return {
      "present": present,
      "pending": pending,
      "leave": leave,
      "absent": absent,
    };
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Scaffold(body: AttendanceSkeleton());
    }

    final summary = calculateSummary();
    final provider = context.watch<PunchProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await loadAttendance();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Attendance",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                Months(
                  onMonthSelected: (month) {
                    setState(() {
                      selectedMonth = month;
                    });
                  },
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("ID: ${provider.employeeId ?? "--"}",
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                SummaryRow(
                  leftCard: SummaryCard(
                    value: summary['present'].toString(),
                    title: "Present",
                    valueColor: Colors.green,
                  ),
                  rightCard: SummaryCard(
                    value: summary['pending'].toString(),
                    title: "Pending",
                    valueColor: Colors.orange,
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                SummaryRow(
                  leftCard: SummaryCard(
                    value: summary['absent'].toString(),
                    title: "Absent",
                    valueColor: Colors.red,
                  ),
                  rightCard: SummaryCard(
                    value: summary['leave'].toString(),
                    title: "Leave",
                    valueColor: AppColors.royalblue,
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                const Text(
                  "Recent Records",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: size.height * 0.01),

                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: itemsLoaded,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: size.height * 0.01),
                    itemBuilder: (context, index) {
                      DateTime date =
                          DateTime.now().subtract(Duration(days: index));

                      final provider = context.read<PunchProvider>();
                      final joiningDate =
                          DateTime.parse(provider.joiningDate);

                      if (date.isBefore(joiningDate)) {
                        return const SizedBox();
                      }

                      final now = DateTime.now();
                      final dateKey =
                          DateFormat('yyyy-MM-dd').format(date);
                      final todayKey =
                          DateFormat('yyyy-MM-dd').format(now);

                      DateTime? punchIn;
                      DateTime? punchOut;
                      String status = "not punchin";

                      final record = attendanceList.firstWhere(
                        (e) => e['date'] == dateKey,
                        orElse: () => {},
                      );

                      final leaveRecord = leaveList.firstWhere((leave) {
                        final start = DateTime.parse(leave['start_date']);
                        final end = DateTime.parse(leave['end_date']);

                        return !date.isBefore(start) && !date.isAfter(end);
                      }, orElse: () => {});

                      final isHoliday = provider.isHoliday(date);
                      final workingDay =
                          isWorkingDay(date, provider.workSchedule);

                      // ---------------- PRIORITY ----------------

                      if (isHoliday || !workingDay) {
                        status = "holiday";
                      } else if (leaveRecord.isNotEmpty) {
                        status = "leave";
                      } else if (record.isNotEmpty) {
                        if (record['status'] == 'approved') {
                          status = "present";
                        } else if (record['status'] == 'pending') {
                          status = "pending";
                        } else {
                          status = "absent";
                        }

                        if (record['punch_in'] != null) {
                          punchIn =
                              DateTime.parse(record['punch_in']);
                        }

                        if (record['punch_out'] != null) {
                          punchOut =
                              DateTime.parse(record['punch_out']);
                        }
                      } else {
                        if (dateKey == todayKey) {
                          final cutoff = DateTime(
                              now.year, now.month, now.day, 10, 30);

                          status = now.isAfter(cutoff)
                              ? "absent"
                              : "not punchin";
                        } else {
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
      ),
    );
  }
}