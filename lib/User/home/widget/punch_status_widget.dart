import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/home/widget/live_work_timer.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class PunchStatusCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;
    final bool isIn = statusText == "Punched In";
    final bool isOut = statusText == "Punched Out";
    final today = DateTime.now();
    final currentUserId = punch.supabase.auth.currentUser?.id;

    /// 🧠 check schedule

    final currentUser = punch.employeeList.firstWhere(
      (u) => u['id'] == currentUserId,
      orElse: () => {},
    );

    final schedule = currentUser['work_schedule'] ?? "mon_sat";

    bool isHoliday = false;

    if (schedule == "mon_fri") {
      isHoliday =
          today.weekday == DateTime.saturday ||
          today.weekday == DateTime.sunday;
    } else {
      isHoliday = today.weekday == DateTime.sunday;
    }

    /// 🧠 check leave
    bool isOnLeave = punch.leaveList.any((leave) {
      if (leave['user_id'] != currentUserId) return false;

      final start = DateTime.parse(leave['start_date']);
      final end = DateTime.parse(leave['end_date']);

      return !today.isBefore(start) && !today.isAfter(end);
    });
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔹 Header Row
            Row(
              children: [
                const Text(
                  "Punch Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnLeave
                        ? Colors.orange.shade100
                        : isHoliday
                        ? Colors.blue.shade100
                        : isIn
                        ? AppColors.shadowgreen
                        : isOut
                        ? AppColors.shadowred
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnLeave
                        ? "On Leave"
                        : isHoliday
                        ? "Holiday"
                        : statusText,
                    style: TextStyle(
                      color: isOnLeave
                          ? Colors.orange
                          : isHoliday
                          ? Colors.blue
                          : isIn
                          ? AppColors.green
                          : isOut
                          ? Colors.red
                          : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.01),

            /// Time Row
            if (!isOnLeave && !isHoliday)
              Consumer<PunchProvider>(
                builder: (context, provider, child) {
                  return Row(
                    children: [
                      const Icon(Icons.access_time, size: 17),
                      SizedBox(width: size.width * 0.02),

                      Text(
                        provider.punchInTime == null
                            ? "In  --:--"
                            : "In  ${DateFormat('hh:mm a').format(provider.punchInTime!)}",
                      ),

                      const Spacer(),

                      const Icon(Icons.access_time, size: 17),
                      SizedBox(width: size.width * 0.01),

                      Text(
                        provider.punchOutTime == null
                            ? "Out  --:--"
                            : "Out  ${DateFormat('hh:mm a').format(provider.punchOutTime!)}",
                      ),
                    ],
                  );
                },
              ),
            if (isOnLeave)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "You are on leave today",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isHoliday)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Enjoy your holiday 🎉",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: size.height * 0.018),
            if (punch.punchStatus == "done")
              /// Live Work Timer
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.shadowgrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    LiveWorkTimer(),
                    SizedBox(width: size.width * 0.0),
                    const Text("Worked Today"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
