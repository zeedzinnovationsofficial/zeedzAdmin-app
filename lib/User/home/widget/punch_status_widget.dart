import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<bool> checkIsHoliday() async {
    final today = DateTime.now();

    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final response = await Supabase.instance.client
        .from('holidays')
        .select()
        .eq('holiday_date', dateStr);

    return response.isNotEmpty;
  }
  

  @override
  Widget build(BuildContext context) {
    final punch = context.watch<PunchProvider>();
    final size = MediaQuery.of(context).size;
    final bool isIn = statusText == "Punched In";
    final bool isOut = statusText == "Punched Out";
    final today = DateTime.now();
    final currentUserId = punch.supabase.auth.currentUser?.id;

    /// 🧠 USER SCHEDULE
    final currentUser = punch.employeeList.firstWhere(
      (u) => u['id'] == currentUserId,
      orElse: () => {},
    );

    final schedule = currentUser['work_schedule'] ?? "mon_sat";

    /// 🧠 LEAVE CHECK
    bool isOnLeave = punch.leaveList.any((leave) {
      if (leave['user_id'] != currentUserId) return false;

      final start = DateTime.parse(leave['start_date']);
      final end = DateTime.parse(leave['end_date']);

      return !today.isBefore(start) && !today.isAfter(end);
    });

    return FutureBuilder<bool>(
      future: checkIsHoliday(),
      builder: (context, snapshot) {
        final dbHoliday = snapshot.data ?? false;

        final isSunday = today.weekday == DateTime.sunday;
        final isSaturday = today.weekday == DateTime.saturday;

        final isWeekend = schedule == "mon_fri"
            ? (isSaturday || isSunday)
            : isSunday;

        /// ✅ FINAL HOLIDAY (LEAVE HAS PRIORITY)
        final isHoliday = !isOnLeave && (dbHoliday || isWeekend);

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
                /// 🔹 HEADER
                Row(
                  children: [
                    const Text(
                      "Punch Status",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                /// ⏱ TIME ROW (HIDE ON LEAVE / HOLIDAY)
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

                /// 🟠 LEAVE MESSAGE
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

                /// 🔵 HOLIDAY MESSAGE
                if (!isOnLeave && isHoliday)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Enjoy your holiday 🎉",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                SizedBox(height: size.height * 0.018),

                /// ⏳ TIMER (BLOCKED ON LEAVE + HOLIDAY)
                if (!isOnLeave &&
                    !isHoliday &&
                    punch.punchStatus == "done")
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
      },
    );
  }
}