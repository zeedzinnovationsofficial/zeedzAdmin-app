import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/attendance/widget/leave_history.dart';
import 'package:zeedz_attendance/User/attendance/widget/months.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';
List<DateTime> getMonthDates(int month, int year) {
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 0); // last day

  List<DateTime> dates = [];

  for (
    DateTime d = start;
    !d.isAfter(end);
    d = d.add(const Duration(days: 1))
  ) {
    dates.add(d);
  }

  return dates;
}
class EmployeesAttendance extends StatefulWidget {
  final Map user;

  const EmployeesAttendance({super.key, required this.user});

  @override
  State<EmployeesAttendance> createState() => _EmployeesAttendanceState();
  
  
}

class _EmployeesAttendanceState extends State<EmployeesAttendance> {
  DateTimeRange? selectedRange;
  List<Map<String, dynamic>> holidayList = [];
  int selectedMonth = DateTime.now().month;
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> leaveList = [];

  int itemsLoaded = 15;
  final int loadMore = 15;
Map<String, int> calculateCycleSummary() {
  final joiningDate = DateTime.parse(widget.user['joining_date']);
  final now = DateTime.now();
  final schedule = widget.user['work_schedule'] ?? "mon_sat";

  int present = 0;
  int pending = 0;
  int leave = 0;
  int absent = 0;


final year = now.year;

final monthDates = getMonthDates(selectedMonth, year);

  for (final d in monthDates) {
    // 🔴 JOINING DATE CHECK (FIRST)
final joiningDate = DateTime.parse(widget.user['joining_date']);
final joinOnly = DateTime(
  joiningDate.year,
  joiningDate.month,
  joiningDate.day,
);

final today = DateTime.now();
final todayOnly = DateTime(today.year, today.month, today.day);

// 🔴 JOINING DATE-KU MUNNADI → SKIP
if (d.isBefore(joinOnly)) continue;

// 🔴 FUTURE DATE → SKIP
if (d.isAfter(todayOnly)) continue;

    final dateOnly = DateTime(d.year, d.month, d.day);

    final dateKey = DateFormat('yyyy-MM-dd').format(dateOnly);

    final record = attendanceList.where((e) {
      final dbDate = DateTime.parse(e['date']);
      final dbKey = DateFormat('yyyy-MM-dd').format(dbDate);
      return dbKey == dateKey;
    }).toList();

    final leaveRecord = leaveList.where((l) {
      final start = DateTime.parse(l['start_date']);
      final end = DateTime.parse(l['end_date']);

      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);

      return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
    }).toList();

    bool isHoliday = false;

// weekly holiday
if (schedule == "mon_fri") {
  isHoliday =
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
} else if (schedule == "mon_sat") {
  isHoliday = d.weekday == DateTime.sunday;
}

// extra holiday from DB
final holidayExists = holidayList.any((h) {
 final raw = h['holiday_date'];
if (raw == null) return false;

final holidayDate = DateTime.parse(raw.toString());

return holidayDate.year == d.year &&
       holidayDate.month == d.month &&
       holidayDate.day == d.day;
});

if (holidayExists) {
  isHoliday = true;
}
// ✅ 1. HOLIDAY FIRST
if (isHoliday) {
  continue;
}

// ✅ 2. LEAVE NEXT
if (leaveRecord.isNotEmpty) {
  leave++;
  continue;
}

if (record.isNotEmpty) {
  final status = (record.first['status'] ?? '').toString().toLowerCase();

  if (status == 'approved' || status == 'present') {
    present++;
  } else if (status == 'pending') {
    pending++;
  } else {
    absent++;
  }
} else {
  if (dateOnly.isBefore(todayOnly)) {
    absent++;
  }
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

 Future<void> loadAttendance() async {
  final attendanceResponse = await supabase
      .from('attendance')
      .select()
      .eq('user_id', widget.user['id'])
      .order('date');

  final leaveResponse = await supabase
      .from('leave_requests')
      .select()
      .eq('user_id', widget.user['id'])
      .eq('status', 'approved');

  final holidayResponse = await supabase
      .from('holidays')
      .select();   // your holiday table name

  setState(() {
    attendanceList = List<Map<String, dynamic>>.from(attendanceResponse);
    leaveList = List<Map<String, dynamic>>.from(leaveResponse);
    holidayList = List<Map<String, dynamic>>.from(holidayResponse);
  });
}
  /// SUMMARY CALCULATION
  Map<String, int> calculateSummary() {
    final joiningDate = DateTime.parse(widget.user['joining_date']);

    final schedule = widget.user['work_schedule'] ?? "mon_sat"; //

    int present = 0;
    int pending = 0;
    int leave = 0;

    final now = DateTime.now();
    final year = now.year;

    final monthStart = DateTime(year, selectedMonth, 1);

    /// start counting from join date
    final start = joiningDate.isAfter(monthStart) ? joiningDate : monthStart;

  final cutoff = DateTime(now.year, now.month, now.day, 11, 0);

final end = selectedMonth == now.month
    ? (now.isAfter(cutoff)
        ? DateTime(year, selectedMonth, now.day)   // ✅ include today
        : DateTime(year, selectedMonth, now.day - 1))
    : DateTime(year, selectedMonth + 1, 0);

    int workingDays = 0;

    /// working days after join date
    for (
      DateTime d = start;
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
        if (d.isBefore(
      DateTime(
        joiningDate.year,
        joiningDate.month,
        joiningDate.day,
      ),
    )) {
      continue;
    }
      if (schedule == "mon_fri") {
        if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
          continue;
      } else if (schedule == "mon_sat") {
        if (d.weekday == DateTime.sunday) continue;
      }
      workingDays++;
    }

    /// attendance count
    for (final record in attendanceList) {
      final recordDate = DateTime.parse(record['date']);

      if (recordDate.month != selectedMonth) continue;
      if (recordDate.isBefore(start)) continue;

      if (selectedMonth == now.month && recordDate.isAfter(now)) continue;
      if (schedule == "mon_fri") {
        if (recordDate.weekday == DateTime.saturday ||
            recordDate.weekday == DateTime.sunday)
          continue;
      } else if (schedule == "mon_sat") {
        if (recordDate.weekday == DateTime.sunday) continue;
      }

      final status = record['status'];

      if (status == 'approved') {
        present++;
      } else if (status == 'pending') {
        pending++;
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

        if (selectedMonth == now.month && d.isAfter(now)) continue;
        if (schedule == "mon_fri") {
          if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
            continue;
        } else if (schedule == "mon_sat") {
          if (d.weekday == DateTime.sunday) continue;
        }

        leave++;
      }
    }

    /// prevent leave exceeding working days
    if (leave > workingDays) leave = workingDays;

    /// calculate absent safely
    int absent = workingDays - (present + pending + leave);

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
    
   final joiningDate = DateTime.parse(widget.user['joining_date']);
final year = DateTime.now().year;
final monthDates = getMonthDates(selectedMonth, year);
   final summary = calculateCycleSummary();
    print("summary: ${summary['absent'].toString()}");

    return Scaffold(
      body: SafeArea(
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
                        "",
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

              SizedBox(height: size.height * 0.0002),
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
                        widget.user['name'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: ${widget.user['employee_id'] ?? "--"}",
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
                  valueColor: Colors.blue,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              const Text(
                "Recent Records",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),


              /// ATTENDANCE LIST
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: monthDates.length,

                  separatorBuilder: (context, index) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.011,
                  ),
                  itemBuilder: (context, index) {
                    final date = monthDates[index];
                    final joiningDate = DateTime.parse(widget.user['joining_date']);
final joinOnly = DateTime(
  joiningDate.year,
  joiningDate.month,
  joiningDate.day,
);

final today = DateTime.now();
final todayOnly = DateTime(today.year, today.month, today.day);

// 🔴 1. JOINING DATE-KU MUNNADI → HIDE
if (date.isBefore(joinOnly)) {
  return const SizedBox();
}

// 🔴 2. FUTURE DATE → HIDE
if (date.isAfter(todayOnly)) {
  return const SizedBox();
}



// 🔴 FUTURE DATE CHECK (FIRST)
if (date.isAfter(todayOnly)) {
  return const SizedBox(); // hide future dates
}

                   
final schedule = widget.user['work_schedule'];

// 🔴 DB HOLIDAY CHECK (FIRST)
final isDbHoliday = holidayList.any((h) {
  final raw = h['holiday_date'];
  if (raw == null) return false;

  final hd = DateTime.parse(raw);
  return hd.year == date.year &&
         hd.month == date.month &&
         hd.day == date.day;
});

// 🔴 WEEKLY HOLIDAY
bool isWeeklyHoliday = false;
if (schedule == "mon_fri") {
  isWeeklyHoliday =
      date.weekday == DateTime.saturday ||
      date.weekday == DateTime.sunday;
} else if (schedule == "mon_sat") {
  isWeeklyHoliday = date.weekday == DateTime.sunday;
}

// ✅ IF HOLIDAY → STOP EVERYTHING HERE
if (isDbHoliday || isWeeklyHoliday) {
  return LeaveHistory(
    date: date,
    punchIn: null,
    punchOut: null,
    status: "holiday",
  );
}
                    
                    
                    print("Join Date: $joiningDate");
                    if (date.isBefore(joiningDate)) {
                      return const SizedBox();
                    }

                    DateTime? punchIn;
DateTime? punchOut;

String status = "";

final dateOnly = DateTime(date.year, date.month, date.day);

final todayDate = DateTime(todayOnly.year, todayOnly.month, todayOnly.day);

final dateKey = DateFormat('yyyy-MM-dd').format(dateOnly);


final record = attendanceList.firstWhere(
  (item) {
    final dbDate = DateTime.parse(item['date']).toLocal();

    return dbDate.year == date.year &&
        dbDate.month == date.month &&
        dbDate.day == date.day;
  },
  orElse: () => {},
);

final leaveRecord = leaveList.firstWhere(
  (leave) {
    final start = DateTime.parse(leave['start_date']).toLocal();
    final end = DateTime.parse(leave['end_date']).toLocal();

    return !date.isBefore(DateTime(start.year, start.month, start.day)) &&
           !date.isAfter(DateTime(end.year, end.month, end.day));
  },
  orElse: () => {},
);



bool isHoliday = false;
if (schedule == "mon_fri") {
  isHoliday =
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
} else if (schedule == "mon_sat") {
  isHoliday = date.weekday == DateTime.sunday;
}

/// 1. FIRST → if attendance record exists
if (record.isNotEmpty) {
  final dbStatus = (record['status'] ?? '').toString().toLowerCase();

  if (dbStatus == 'approved' || dbStatus == 'present') {
    status = "present";
  } else if (dbStatus == 'pending') {
    status = "pending";
  } else if (dbStatus == 'rejected' || dbStatus == 'absent') {
    status = "absent";
  }

  if (record['punch_in'] != null) {
    punchIn = DateTime.parse(record['punch_in']);
  }

  if (record['punch_out'] != null) {
    punchOut = DateTime.parse(record['punch_out']);
  }
}

/// 2. leave
else if (leaveRecord.isNotEmpty) {
  status = "leave";
}

/// 3. holiday
else if (isHoliday) {
  status = "holiday";
}

/// 4. today
else if (dateOnly == todayDate) {
  status = "not punchin";
}

/// 5. previous day no record
else if (dateOnly.isBefore(todayDate)) {
  // check if it's working day first

  bool isWeekend = false;

  if (schedule == "mon_fri") {
    isWeekend = date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday;
  } else if (schedule == "mon_sat") {
    isWeekend = date.weekday == DateTime.sunday;
  }

  final holidayExists = holidayList.any((h) {
    final raw = h['holiday_date'];
    if (raw == null) return false;

    final holidayDate = DateTime.parse(raw.toString());
    return holidayDate.year == date.year &&
           holidayDate.month == date.month &&
           holidayDate.day == date.day;
  });

  final isLeave = leaveRecord.isNotEmpty;

  if (!isWeekend && !holidayExists && !isLeave) {
    status = "absent";
  } else {
    status = "";
  }
}

/// 6. future
else {
  status = "";
}

return LeaveHistory(
  date: date,
  punchIn: punchIn,
  punchOut: punchOut,
  status: status,
);}
                ),
              ),
            ],
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

    // ignore: unused_local_variable
    final user = provider.supabase.auth.currentUser;

    final response = await provider.supabase
        .from('attendance')
        .select()
        .eq('user_id', widget.user['id'])
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0])
        .order('date');

    final list = List<Map<String, dynamic>>.from(response);

    int present = 0;
    int pending = 0;
    int leave = 0;
    int absent = 0;

    List<List<String>> tableData = [];

    DateTime current = start;
    final leaveResponse = await provider.supabase
        .from('leave_requests')
        .select('start_date, end_date, leave_type')
        .eq('user_id', widget.user['id'])
        .eq('status', 'approved');

    final leaveList = List<Map<String, dynamic>>.from(leaveResponse);
    while (!current.isAfter(end)) {
      final record = list.firstWhere(
        (e) =>
            e['date'] ==
            "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}",
        orElse: () => {},
      );
      bool isHoliday = false;
      String status = "Absent";
      String leaveType = "";
      String punchIn = "-";
      String punchOut = "-";
      String location = "-";
      final workSchedule = widget.user['work_schedule'];

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
          leave++;
          leaveType = leaveData['leave_type'] ?? "";
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
        } else if (dbStatus == "leave") {
          status = "Leave";
          leave++;
        }

        if (record['punch_in'] != null) {
  final pIn = DateTime.parse(record['punch_in']); // ✅ FIX
  punchIn = DateFormat('hh:mm a').format(pIn);
}

if (record['punch_out'] != null) {
  final pOut = DateTime.parse(record['punch_out']); // ✅ FIX
  punchOut = DateFormat('hh:mm a').format(pOut);
}

        location = record['punch_out_location'] ?? "-";
      } else {
        absent++;
      }
      String paid = leaveType == 'paid' ? "paid" : "";
      String unpaid = leaveType == 'unpaid' ? "unpaid" : "";

      final row = [
        "${current.day.toString().padLeft(2, '0')}-${current.month.toString().padLeft(2, '0')}-${current.year}",
        status,
        paid,
        unpaid,
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

          pw.Text("Employee Name : ${widget.user['name'] ?? '-'}"),
          pw.Text("Department : ${widget.user['department'] ?? '-'}"),
          pw.Text("Employee ID : ${widget.user['employee_id'] ?? '-'}"),

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
