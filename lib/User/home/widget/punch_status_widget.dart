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
  Map<String, dynamic>? cachedHoliday;
  late Future<void> initFuture;

  @override
  void initState() {
    super.initState();
    initFuture = loadHolidayOnce();
  }

  Future<void> loadHolidayOnce() async {
    final today = DateTime.now();

    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final response = await Supabase.instance.client
        .from('holidays')
        .select()
        .eq('holiday_date', dateStr)
        .maybeSingle();

    cachedHoliday = response;
  }

  @override
  Widget build(BuildContext context) {
    final punch = context.select((PunchProvider p) => p);
    final size = MediaQuery.of(context).size;

    final today = DateTime.now();
    final currentUserId = punch.supabase.auth.currentUser?.id;

    final currentUser = punch.employeeList.firstWhere(
      (u) => u['id'] == currentUserId,
      orElse: () => {},
    );

    final schedule = currentUser['work_schedule'] ?? "mon_sat";

    bool isOnLeave = punch.leaveList.any((leave) {
      if (leave['user_id'] != currentUserId) return false;
      if (leave['status'] != 'approved') return false;

      final start = DateTime.parse(leave['start_date']);
      final end = DateTime.parse(leave['end_date']);

      final todayOnly = DateTime(today.year, today.month, today.day);
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);

      return !todayOnly.isBefore(startOnly) &&
          !todayOnly.isAfter(endOnly);
    });

    final isSunday = today.weekday == DateTime.sunday;
    final isSaturday = today.weekday == DateTime.saturday;

    final isWeekend = schedule == "mon_fri"
        ? (isSaturday || isSunday)
        : isSunday;

    final isHoliday = !isOnLeave && (cachedHoliday != null || isWeekend);
    final holidayName = cachedHoliday?['name'] ?? "Holiday";

    String statusText;
    Color bgColor;
    Color textColor;

    if (isOnLeave) {
      statusText = "On Leave";
      bgColor = AppColors.shadowroyalblue;
      textColor = AppColors.royalblue;
    } else if (isHoliday) {
      statusText = "Holiday";
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue;
    } else if (punch.punchOutTime != null) {
      statusText = "Punched Out";
      bgColor = AppColors.shadowred;
      textColor = Colors.red;
    } else if (punch.punchInTime != null) {
      statusText = "Pending";
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange;
    } else {
      statusText = "Punch In";
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey;
    }

    return FutureBuilder(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PunchStatusSkeleton();
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
                Row(
                  children: [
                    const Text(
                      "Punch Status",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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

                if (!isOnLeave && !isHoliday)
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

               if (!isOnLeave && isHoliday)
                Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        /// TIMELINE DOT + LINE
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
                  color: Colors.blue.shade100,
                ),
              ],
            ),

          const SizedBox(width: 12),

        /// CONTENT
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
                /// TITLE ROW
                Row(
                  children: const [
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

                /// REASON (IMPORTANT PART)
                Text(
                  holidayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 4),

                /// SMALL TAG
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
                if (!isOnLeave &&
                    !isHoliday &&
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