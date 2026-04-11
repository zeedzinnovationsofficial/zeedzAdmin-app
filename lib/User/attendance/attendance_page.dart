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
    print("Test 11");
    print("AttendancePage INIT 🔥");
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
      return d.weekday != DateTime.sunday; // fallback
    }
  }

  Future<void> loadAttendance() async {
    print("Test 1");
    final user = supabase.auth.currentUser;
    print("Test 2");
    if (user == null) return;
    print("Test 3");
    final attendanceResponse = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .order('date');
    print("Test 4");
    final leaveResponse = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'approved');
    print("Test 5");
    setState(() {
      attendanceList = List<Map<String, dynamic>>.from(attendanceResponse);
      print("attendanceList: ${attendanceList}");
      leaveList = List<Map<String, dynamic>>.from(leaveResponse);
      isLoading = false;
    });
  }

  /// SUMMARY CALCULATION
  Map<String, int> calculateSummary() {
    final joiningDate = DateTime.parse(
      context.read<PunchProvider>().joiningDate,
    );
    print("Join date emp: $joiningDate");
    final schedule = context
        .read<PunchProvider>()
        .workSchedule; // mon_fri or mon_sat
    print("Schedule => $schedule");
    int present = 0;
    int pending = 0;
    int leave = 0;

    final now = DateTime.now();
    final year = now.year;

    final monthStart = DateTime(year, selectedMonth, 1);

    /// start counting from join date
    final start = joiningDate.isAfter(monthStart) ? joiningDate : monthStart;

    final end = selectedMonth == now.month
        ? DateTime(year, selectedMonth, now.day)
        : DateTime(year, selectedMonth + 1, 0);

    int workingDays = 0;

    bool isWorkingDay(DateTime d) {
      if (schedule == "mon_fri") {
        return d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;
      } else {
        return d.weekday != DateTime.sunday;
      }
    }

    /// working days
    for (
      DateTime d = start;
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      if (!isWorkingDay(d)) continue;
      workingDays++;
    }

    /// attendance count
    int absent = 0;

    for (final record in attendanceList) {
      final recordDate = DateTime.parse(record['date']);

      if (recordDate.month != selectedMonth) continue;
      if (recordDate.isBefore(start)) continue;
      if (!isWorkingDay(recordDate)) continue;

      if (selectedMonth == now.month && recordDate.isAfter(now)) continue;

      final status = record['status'];
      print("status :$status");
      if (status == 'approved') {
        present++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'Absent' || status == 'rejected') {
        absent++;

        print("absent :$absent");
      }
    }

    /// leave count
    for (final leaveItem in leaveList) {
      final startDate = DateTime.parse(leaveItem['start_date']);
      final endDate = DateTime.parse(leaveItem['end_date']);

      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month != selectedMonth) continue;
        if (d.isBefore(start)) continue;
        if (!isWorkingDay(d)) continue;

        if (selectedMonth == now.month && d.isAfter(now)) continue;

        leave++;
      }
    }

    if (leave > workingDays) leave = workingDays;

    if (absent < 0) absent = 0;

    return {
      "present": present,
      "pending": pending,
      "leave": leave,
      "absent": absent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isLoading) {
      return const Scaffold( body: AttendanceSkeleton(),);
    }
    final summary = calculateSummary();
    print("summary['absent'].toString() ${summary['absent'].toString()}");
    final provider = context.watch<PunchProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await loadAttendance(); // ✅ IMPORTANT
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Attendance",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    /// DOWNLOAD ICON
                    IconButton(
                      icon: const Icon(Icons.download_for_offline_outlined),
                      onPressed: () async {
                        final parentContext = context;

                        final picked = await showDateRangePicker(
                          context: parentContext,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          helpText: "Select Attendance Range",
                        );

                        if (picked == null) return;

                        final start = picked.start;
                        final end = picked.end;

                        showDialog(
                          context: parentContext,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Download Attendance"),
                              content: Text(
                                "Download attendance from\n"
                                "${start.day}-${start.month}-${start.year}\n"
                                "to\n"
                                "${end.day}-${end.month}-${end.year} ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),

                                ElevatedButton(
                                  child: const Text("Download"),
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    await generateAttendancePdf(
                                      parentContext,
                                      start,
                                      end,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
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

                /// EMPLOYEE INFO
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: size.width * 0.06),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "ID: ${provider.employeeId ?? "--"}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // IconButton(
                    //   icon: const Icon(Icons.calendar_month),
                    //   onPressed: () async {
                    //     final DateTimeRange? picked = await showDateRangePicker(
                    //       context: context,
                    //       firstDate: DateTime(2000),
                    //       lastDate: DateTime.now(),
                    //     );

                    //     if (picked != null) {
                    //       setState(() {
                    //         selectedRange = picked;
                    //       });

                    //       context.read<PunchProvider>().filterAttendanceByDate(
                    //         picked.start,
                    //         picked.end,
                    //       );
                    //     }
                    //   },
                    // ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                /// SUMMARY
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

                /// ATTENDANCE LIST
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: itemsLoaded,
                    separatorBuilder: (context, index) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.011,
                    ),
                    itemBuilder: (context, index) {
                      DateTime date = DateTime.now().subtract(
                        Duration(days: index),
                      );
                      final joiningDate = DateTime.parse(
                        context.read<PunchProvider>().joiningDate,
                      );

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
                        final start = DateTime.parse(
                          leave['start_date'],
                        ).toIso8601String().split('T')[0];

                        final end = DateTime.parse(
                          leave['end_date'],
                        ).toIso8601String().split('T')[0];

                        return dateKey.compareTo(start) >= 0 &&
                            dateKey.compareTo(end) <= 0;
                      }, orElse: () => {});

                      // Leave
                      if (leaveRecord.isNotEmpty) {
                        status = "leave";
                      }
                      // Attendance record exists
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
                      // No DB record
                      else {
                        final workSchedule = context
                            .read<PunchProvider>()
                            .workSchedule;

                        final isHoliday = !isWorkingDay(date);

                        if (isHoliday) {
                          status = "holiday";
                        } else {
                          if (dateKey == todayKey) {
                            final cutoff = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              23,
                              59,
                            );

                            if (now.isAfter(cutoff)) {
                              status = "absent";
                            } else {
                              status = "not punchin";
                            }
                          } else if (date.isBefore(now)) {
                            status =
                                "absent"; // ✅ Past day with no punch = absent
                          }
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
                SizedBox(height: size.height * 0.07),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> generateAttendancePdf(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) async {
    final provider = context.read<PunchProvider>();

    final user = provider.supabase.auth.currentUser;

    final response = await provider.supabase
        .from('attendance')
        .select()
        .eq('user_id', user!.id)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0])
        .order('date');

    final list = List<Map<String, dynamic>>.from(response);

    int present = 0;
    int pending = 0;
    int leave = 0;
    int absent = 0;

    List<List<String>> tableData = [];
    final userData = await provider.supabase
        .from('users')
        .select('work_schedule')
        .eq('id', user.id)
        .single();

    final workSchedule = userData['work_schedule'];
    DateTime current = start;
    final leaveResponse = await provider.supabase
        .from('leave_requests')
        .select('start_date, end_date, leave_type')
        .eq('user_id', user.id)
        .eq('status', 'approved');

    final leaveList = List<Map<String, dynamic>>.from(leaveResponse);
    while (!current.isAfter(end)) {
      final record = list.firstWhere(
        (e) =>
            e['date'] ==
            "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}",
        orElse: () => {},
      );

      String status = "Absent";
      String punchIn = "-";
      String punchOut = "-";
      String location = "-";
      String leaveType = "";

      bool isHoliday = false;

      // 🔥 HOLIDAY CHECK
      if (workSchedule == "mon_fri") {
        if (current.weekday == DateTime.saturday ||
            current.weekday == DateTime.sunday) {
          isHoliday = true;
        }
      } else if (workSchedule == "mon_sat") {
        if (current.weekday == DateTime.sunday) {
          isHoliday = true;
        }
      }

      if (isHoliday) {
        status = "Holiday";
      }
      for (final leaveData in leaveList) {
        final startLeave = DateTime.parse(leaveData['start_date']);
        final endLeave = DateTime.parse(leaveData['end_date']);

        if (!current.isBefore(startLeave) && !current.isAfter(endLeave)) {
          status = "Leave";
          leaveType = leaveData['leave_type'] ?? "unpaid";
          leave++;
          break;
        }
      }
      if (record.isNotEmpty) {
        final dbStatus = record['status'] ?? "pending";

        if (dbStatus == "approved") {
          status = "Present";
          present++;
        } else if (dbStatus == "pending") {
          status = "Pending";
          pending++;
        }

        if (record['punch_in'] != null) {
          final pIn = DateTime.parse(record['punch_in']);
          punchIn = DateFormat('hh:mm a').format(pIn);
        }

        if (record['punch_out'] != null) {
          final pOut = DateTime.parse(record['punch_out']);
          punchOut = DateFormat('hh:mm a').format(pOut);
        }

        location = record['location'] ?? "-";
      } else {
        absent++;
      }
      String paid = leaveType == 'paid' ? "Paid" : "";
      String unpaid = leaveType == 'unpaid' ? "Unpaid" : "";

      final row = [
        "${current.day.toString().padLeft(2, '0')}-${current.month.toString().padLeft(2, '0')}-${current.year}",
        status,
        paid, // 👈 NEW
        unpaid, // 👈 NEW
        punchIn,
        punchOut,
        location,
      ];

      tableData.add(row);

      current = current.add(const Duration(days: 1));
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text(
            "Attendance Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Text("Employee Name : ${provider.name}"),
          pw.Text("Department : ${provider.department}"),
          pw.Text("Employee ID : ${provider.employeeId ?? '-'}"),

          pw.SizedBox(height: 10),

          pw.Text(
            "Date Range : ${start.day}-${start.month}-${start.year}  to  ${end.day}-${end.month}-${end.year}",
          ),

          pw.SizedBox(height: 20),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Present : $present"),
              pw.Text("Pending : $pending"),
              pw.Text("Leave : $leave"),
              pw.Text("Absent : $absent"),
            ],
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              "Date",
              "Status",
              "Paid Leave",
              "Unpaid Leave",
              "Punch In",
              "Punch Out",
              "Location",
            ],
            data: tableData,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    try {
      final dir = Directory('/storage/emulated/0/Download');

      final fileName =
          "attendance_${start.day}-${start.month}-${start.year}_to_${end.day}-${end.month}-${end.year}.pdf";

      final file = File("${dir.path}/$fileName");

      await file.writeAsBytes(await pdf.save());

      /// SHOW MESSAGE FIRST
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PDF downloaded successfully")));

      /// THEN OPEN PDF
      OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PDF download failed")));
    }
  }
}
