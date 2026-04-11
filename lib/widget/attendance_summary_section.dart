import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';

class AttendanceSummaryWidget extends StatefulWidget {
  final int month;

  const AttendanceSummaryWidget({super.key, required this.month});

  @override
  State<AttendanceSummaryWidget> createState() =>
      _AttendanceSummaryWidgetState();
}

class _AttendanceSummaryWidgetState extends State<AttendanceSummaryWidget> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> leaveList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  DateTime? safeParse(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  Future<void> loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final attendanceResponse = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id);

    final leaveResponse = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'approved');

    setState(() {
      attendanceList =
          List<Map<String, dynamic>>.from(attendanceResponse);
      leaveList = List<Map<String, dynamic>>.from(leaveResponse);
      isLoading = false;
    });
  }

  Map<String, int> calculateSummary() {
    final provider = context.read<PunchProvider>();

    DateTime? joiningDate = safeParse(provider.joiningDate);
    final schedule = provider.workSchedule;

    int present = 0;
    int pending = 0;
    int leave = 0;
    int absent = 0;

    final now = DateTime.now();
    final year = now.year;

    final monthStart = DateTime(year, widget.month, 1);
    final start = joiningDate == null
        ? monthStart
        : (joiningDate.isAfter(monthStart) ? joiningDate : monthStart);

    final end = widget.month == now.month
        ? DateTime(year, widget.month, now.day)
        : DateTime(year, widget.month + 1, 0);

    bool isWorkingDay(DateTime d) {
      if (schedule == "mon_fri") {
        return d.weekday != DateTime.saturday &&
            d.weekday != DateTime.sunday;
      } else {
        return d.weekday != DateTime.sunday;
      }
    }

    for (final record in attendanceList) {
      final recordDate = safeParse(record['date']);
      if (recordDate == null) continue;

      if (recordDate.month != widget.month) continue;
      if (recordDate.isBefore(start)) continue;
      if (!isWorkingDay(recordDate)) continue;
      if (widget.month == now.month && recordDate.isAfter(now)) continue;

      final status = record['status'];

      if (status == 'approved') {
        present++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'absent' || status == 'rejected') {
        absent++;
      }
    }

    for (final leaveItem in leaveList) {
      final startDate = safeParse(leaveItem['start_date']);
      final endDate = safeParse(leaveItem['end_date']);

      if (startDate == null || endDate == null) continue;

      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month != widget.month) continue;
        if (d.isBefore(start)) continue;
        if (!isWorkingDay(d)) continue;
        if (widget.month == now.month && d.isAfter(now)) continue;

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = calculateSummary();

    return Column(
      children: [
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
      ],
    );
  }
}