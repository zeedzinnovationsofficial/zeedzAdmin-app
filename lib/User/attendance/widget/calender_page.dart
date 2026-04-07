import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  String reasonText = "";
  String statusText = "";
  final supabase = Supabase.instance.client;

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  Map<DateTime, Map<String, dynamic>> attendanceData = {};

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  /// LOAD DATA FROM DATABASE
  Future<void> loadAttendance() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final attendance = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id);

    final leaves = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'approved');

    Map<DateTime, Map<String, dynamic>> data = {};

    /// Attendance records
    for (var item in attendance) {
      if (item['punch_in'] == null) continue;

      DateTime date = DateTime.parse(item['punch_in']).toLocal();

      DateTime day = DateTime(date.year, date.month, date.day);

      data[day] = {
        "status": item['status'] ?? "pending",
        "reason": item['reject_reason'] ?? "",
      };
    }

    /// Leave records
    for (var leave in leaves) {
      DateTime start = DateTime.parse(leave['start_date']);
      DateTime end = DateTime.parse(leave['end_date']);

      for (
        DateTime d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))
      ) {
        DateTime day = DateTime(d.year, d.month, d.day);

        data[day] = {"status": "leave", "reason": leave['reason'] ?? ""};
      }
    }

    setState(() {
      attendanceData = data;
    });
  }

  /// COLOR BASED ON STATUS
  Color getColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      case "leave":
        return Colors.orange;

      case "pending":
        return Colors.blue;

      default:
        return Colors.transparent;
    }
  }

  /// SHOW REASON POPUP
  void showReason(Map<String, dynamic> data) {
    final status = data['status'];
    final reason = data['reason'] ?? "";

    if (status == "leave" || status == "rejected" || status == "absent") {
      setState(() {
        statusText = status.toUpperCase();
        reasonText = reason.isEmpty ? "No reason available" : reason;
      });
    } else {
      setState(() {
        statusText = "";
        reasonText = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: 480,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          /// CALENDAR
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: focusedDay,

            availableCalendarFormats: const {CalendarFormat.month: 'Month'},

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),

              /// Selected date outline
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),

              selectedTextStyle: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            selectedDayPredicate: (day) => isSameDay(selectedDay, day),

            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });

              DateTime day = DateTime(
                selected.year,
                selected.month,
                selected.day,
              );

              final data = attendanceData[day];

              if (data != null) {
                showReason(data);
              } else {
                setState(() {
                  reasonText = "";
                  statusText = "";
                });
              }
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                /// Sunday Holiday
                if (day.weekday == DateTime.sunday) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${day.day}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data =
                    attendanceData[DateTime(day.year, day.month, day.day)];

                if (data == null) return null;

                final status = data['status'];

                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: getColor(status),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// REASON TEXT BELOW CALENDAR
          if (reasonText.isNotEmpty)
            Container(
              height: size.height * 0.07,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightgrey,
                    blurRadius: 2,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "$statusText : $reasonText",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
