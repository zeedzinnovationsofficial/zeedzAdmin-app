import 'package:zeedz_attendance/provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeChartHelper {
 static  Map<String, int> getCycleChart(PunchProvider punch) {
  final now = DateTime.now();

  

  final joiningDate = DateTime.parse(punch.joiningDate);
  final schedule = punch.workSchedule;

  int present = 0;
  int pending = 0;
  int leave = 0;
  int absent = 0;

DateTime cycleStart;
DateTime cycleEnd;

if (now.day >= 25) {
  cycleStart = DateTime(now.year, now.month, 25);
  cycleEnd = DateTime(now.year, now.month + 1, 24);
} else {
  cycleStart = DateTime(now.year, now.month - 1, 25);
  cycleEnd = DateTime(now.year, now.month, 24);
}
 
 

if (cycleEnd.isAfter(now)) {
  cycleEnd = now;
}

  bool isWorkingDay(DateTime d) {
    if (schedule == "mon_fri") {
      return d.weekday != DateTime.saturday &&
          d.weekday != DateTime.sunday;
    }

    return d.weekday != DateTime.sunday;
  }

  for (
    DateTime date = cycleStart;
    !date.isAfter(cycleEnd) && !date.isAfter(now);
    date = date.add(const Duration(days: 1))
  ) {
    if (!isWorkingDay(date) || punch.isHoliday(date)) {
      continue;
    }

    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  if (punch.attendanceList.isNotEmpty) {
  print(punch.attendanceList.first);
}

final currentUserId =
    Supabase.instance.client.auth.currentUser?.id;

final records = punch.attendanceList.where((item) {
  return item['user_id'] == currentUserId &&
      item['date'].toString().substring(0, 10) == dateKey;
}).toList();
    final leaveRecords = punch.leaveList.where((leaveItem) {
      final startLeave = DateTime.parse(leaveItem['start_date']);
      final endLeave = DateTime.parse(leaveItem['end_date']);

      return !date.isBefore(startLeave) &&
          !date.isAfter(endLeave);
    }).toList();

    // ✅ ATTENDANCE EXISTS
    if (records.isNotEmpty) {
    if (records.isEmpty) continue;

final row = records.first;

      final status =
          (row['status'] ?? '').toString().toLowerCase();

      if (status == 'leave') {
        leave++;
      } else if (
          status == 'pending' ||
          status == 'in' ||
          status == 'punch_in') {
        pending++;
      } else if (
          status == 'approved' ||
          status == 'present' ||
          status == 'out') {
        present++;
      } else if (status == 'absent') {
        absent++;
      }
    }

    // ✅ LEAVE
    else if (leaveRecords.isNotEmpty) {
      leave++;
    }

    // ✅ ABSENT
    else {
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      if (date.isBefore(today)) {
        absent++;
      }
    }
  }

  print("PRESENT: $present");
  print("ABSENT: $absent");
  print("LEAVE: $leave");
  print("PENDING: $pending");

  return {
    "present": present,
    "absent": absent,
    "leave": leave,
    "pending": pending,
  };
}
static Map<String, int> getMonthlyChart(
  PunchProvider provider,
  DateTime month,
) {
  int present = 0;
  int absent = 0;
  int leave = 0;
  int pending = 0;

  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);

  final currentUserId =
    Supabase.instance.client.auth.currentUser?.id;

for (final a in provider.attendanceList) {
  final date = DateTime.parse(a['date']).toLocal();

  if (a['user_id'] != currentUserId) continue;

  if (date.isBefore(start) || date.isAfter(end)) continue;

  final status = (a['status'] ?? '').toString().toLowerCase();

  if (status.contains('present') ||
      status.contains('approved') ||
      status.contains('out')) {
    present++;
  } else if (status.contains('absent')) {
    absent++;
  } else if (status.contains('leave')) {
    leave++;
  } else if (status.contains('pending') ||
      status.contains('in') ||
      status.contains('punch')) {
    pending++;
  }

  }

  return {
    "present": present,
    "absent": absent,
    "leave": leave,
    "pending": pending,
  };
}
}