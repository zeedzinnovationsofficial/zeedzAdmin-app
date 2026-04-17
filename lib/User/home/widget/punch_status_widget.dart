import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/home/widget/live_work_timer.dart';
import 'package:zeedz_attendance/widget/punchstatusskeleton.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class PunchStatusCard extends StatefulWidget {
  final String statusText;
  final String inTime;
  final String outTime;
  final String workedHours;
  final DateTime? punchInTime;
  final bool isRunning;

  const PunchStatusCard({
    super.key,
    required this.statusText,
    required this.inTime,
    required this.outTime,
    required this.workedHours,
    this.punchInTime,
    required this.isRunning,
  });

  @override
  State<PunchStatusCard> createState() => _PunchStatusCardState();
}

class _PunchStatusCardState extends State<PunchStatusCard> {
  late Future<Map<String, dynamic>?> initFuture;

  @override
  void initState() {
    super.initState();
    initFuture = loadHolidayOnce();
  }

  Future<Map<String, dynamic>?> loadHolidayOnce() async {
    final today = DateTime.now();

    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final response = await Supabase.instance.client
        .from('holidays')
        .select()
        .eq('holiday_date', dateStr)
        .maybeSingle();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;

    final today = DateTime.now();
    final currentUserId = punch.supabase.auth.currentUser?.id;

    final currentUser = punch.employeeList.firstWhere(
      (u) => u['id'] == currentUserId,
      orElse: () => {},
    );

    final schedule = currentUser['work_schedule'] ?? "mon_sat";

    /// ✅ FIXED: safe leave check
    final isOnLeave = punch.leaveList.any((leave) {
      if (leave['user_id'] != currentUserId) return false;
      if (leave['status'] != 'approved') return false;

      final start = DateTime.parse(leave['start_date']);
      final end = DateTime.parse(leave['end_date']);

      final t = DateTime(today.year, today.month, today.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);

      return (t.isAtSameMomentAs(s) || t.isAfter(s)) &&
          (t.isAtSameMomentAs(e) || t.isBefore(e));
    });

    final isSunday = today.weekday == DateTime.sunday;
    final isSaturday = today.weekday == DateTime.saturday;

    final isWeekend = schedule == "mon_fri"
        ? (isSaturday || isSunday)
        : isSunday;

    return FutureBuilder<Map<String, dynamic>?>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PunchStatusSkeleton();
        }

        final holiday = snapshot.data;
        final isHoliday = holiday != null;
        final holidayName = holiday?['name'] ?? "Holiday";

        /// =========================
        /// ✅ STATUS LOGIC FIXED
        /// =========================
        String statusText;
        Color bgColor;
        Color textColor;

        if (isOnLeave) {
          statusText = "On Leave";
          bgColor = AppColors.shadowroyalblue;
          textColor = AppColors.royalblue;
        } 
        else if (isHoliday) {
          statusText = "Holiday";
          bgColor = Colors.blue.shade100;
          textColor = Colors.blue;
        } 
        else if (isWeekend) {
          statusText = "Weekend";
          bgColor = Colors.blue.shade50;
          textColor = Colors.blueGrey;
        } 
        else if (punch.punchOutTime != null) {
          statusText = "Punched Out";
          bgColor = AppColors.shadowred;
          textColor = Colors.red;
        } 
        else if (punch.punchInTime != null) {
          statusText = "Pending";
          bgColor = Colors.orange.shade100;
          textColor = Colors.orange;
        } 
        else {
          statusText = "Punch In";
          bgColor = Colors.grey.shade200;
          textColor = Colors.grey;
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: AppColors.lightgrey, blurRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// HEADER
                Row(
                  children: [
                    const Text(
                      "Punch Status",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.01),

                /// IN / OUT TIME
                if (!isOnLeave && !isHoliday && !isWeekend)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 17),
                      SizedBox(width: size.width * 0.02),
                      Text(
                        punch.punchInTime == null
                            ? "In  --:--"
                            : "In  ${DateFormat('hh:mm a').format(punch.punchInTime!)}",
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 17),
                      SizedBox(width: size.width * 0.01),
                      Text(
                        punch.punchOutTime == null
                            ? "Out  --:--"
                            : "Out  ${DateFormat('hh:mm a').format(punch.punchOutTime!)}",
                      ),
                    ],
                  ),

                /// LEAVE UI
                if (isOnLeave)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "You are on leave today",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                /// HOLIDAY UI (UNCHANGED DESIGN)
                if (!isOnLeave && isHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      "🎉 Holiday",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "EVENT",
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  holidayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Office Closed • No Attendance Required",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// WORK TIMER
                if (!isOnLeave &&
                    !isHoliday &&
                    !isWeekend &&
                    punch.punchStatus == "done")
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.shadowgrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        LiveWorkTimer(),
                        SizedBox(width: 10),
                        Text("Worked Today"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}