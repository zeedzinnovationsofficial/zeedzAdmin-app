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
String getAttendanceLabel(Map<String, dynamic> a) {
  final status = a['status'];
  final punchIn = a['punch_in'];

  if (punchIn == null) return 'Not Punch In';

  if (status == 'pending') return 'Pending Approval';
  if (status == 'present') return 'Present';
  if (status == 'rejected') return 'Rejected';

  return 'Pending';
}

Color getStatusColor(String label) {
  switch (label) {
    case 'Present':
      return Colors.green;
    case 'Pending Approval':
      return Colors.orange;
    case 'Rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
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
  final provider = context.read<PunchProvider>();
  final joiningDate = DateTime.parse(provider.joiningDate);
  final now = DateTime.now();

  int present = 0;
  int pending = 0;
  int leave = 0;
  int absent = 0;

  // selected month start
  DateTime selectedMonthDate = DateTime(now.year, selectedMonth, 1);

  // cycle start = joining day in selected month
  DateTime cycleStart = DateTime(
    selectedMonthDate.year,
    selectedMonthDate.month,
    joiningDate.day,
  );

  // if selected month before joining month skip
  if (cycleStart.isBefore(joiningDate)) {
    cycleStart = joiningDate;
  }

  // cycle end = next month joining day - 1
  DateTime cycleEnd = DateTime(
    cycleStart.year,
    cycleStart.month + 1,
    joiningDate.day,
  ).subtract(const Duration(days: 1));

  // current month -> only till today
  if (cycleEnd.isAfter(now)) {
    cycleEnd = now;
  }

  for (
    DateTime d = cycleStart;
    !d.isAfter(cycleEnd);
    d = d.add(const Duration(days: 1))
  ) {
   final normalizedDate = DateTime(d.year, d.month, d.day);

if (provider.isHoliday(normalizedDate)) {
  continue; // skip holiday from count
}

if (!isWorkingDay(normalizedDate)) {
  continue; // skip weekend
}
    final dateKey = DateFormat('yyyy-MM-dd').format(d);

    final record = attendanceList.where((e) {
      final dbDate = e['date'].toString().substring(0, 10);
      return dbDate == dateKey;
    }).toList();

    final leaveRecord = leaveList.where((l) {
      final start = DateTime.parse(l['start_date']);
      final end = DateTime.parse(l['end_date']);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    if (leaveRecord.isNotEmpty) {
      leave++;
      continue;
    }

    if (record.isNotEmpty) {
      final status =
          (record.first['status'] ?? '').toString().toLowerCase();

      if (status == 'approved' || status == 'present') {
        present++;
      } else if (status == 'pending') {
        pending++;
      } else {
        absent++;
      }
    } else {
      absent++;
    }
  }

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

                      String status = "";

                      final dateKey =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                      final todayKey =
                          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                      final record = attendanceList.firstWhere(
  (item) {
    final dbDate = DateTime.parse(item['date'])
        .toIso8601String()
        .split('T')[0];
    return dbDate == dateKey;
  },
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
  final dbStatus = (record['status'] ?? '').toString().toLowerCase();
  final hasPunchIn = record['punch_in'] != null;
  final hasPunchOut = record['punch_out'] != null;

 if (dbStatus == 'present' || dbStatus == 'approved') {
  status = 'present';
}
else if (dbStatus == 'pending') {
  status = 'pending';
}
else if (dbStatus == 'rejected') {
  status = 'rejected';
}
else {
  status = 'not punchin';
}

  if (hasPunchIn) {
    punchIn = DateTime.parse(record['punch_in']).toLocal();
  }
  if (hasPunchOut) {
    punchOut = DateTime.parse(record['punch_out']).toLocal();
  }
}
 final provider = context.read<PunchProvider>();

// 🔥 ONLY APPLY WHEN NO DB RECORD
if (record.isEmpty) {
  if (provider.isHoliday(date) || !isWorkingDay(date)) {
    status = "holiday";
  } else if (leaveRecord.isNotEmpty) {
    status = "leave";
  } else if (dateKey == todayKey) {
    status = "not punchin";
  } else {
    // 🔥 old deleted data should not auto become absent
    final now = DateTime.now();
    final isCurrentMonth =
        date.month == now.month && date.year == now.year;

    if (isCurrentMonth) {
      status = "absent";
    } else {
      status = "present"; // keep old history visible
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
