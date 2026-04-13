import 'package:flutter/material.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class LeaveHistory extends StatelessWidget {
  final DateTime date;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final String status;

  const LeaveHistory({
    super.key,
    required this.date,
    this.punchIn,
    this.punchOut,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusBg;
    Color statusColor;
    final today = DateTime.now();
    final itemDate = DateTime(date.year, date.month, date.day);

    final isToday =
        itemDate.year == today.year &&
        itemDate.month == today.month &&
        itemDate.day == today.day;
    if (status == "holiday") {
      statusText = "Holiday";
      statusBg = Colors.grey.shade200;
      statusColor = Colors.blue;
    } else {
      switch (status) {
        case 'holiday':
          statusText = "Holiday";
          statusBg = Colors.grey.shade200;
          statusColor = Colors.blue;
          break;
        case 'present':
        case 'approved':
          statusText = "Present";
          statusBg = AppColors.shadowgreen;
          statusColor = AppColors.green;
          break;

        case 'pending':
          statusText = "Pending";
          statusBg = Colors.orange.shade100;
          statusColor = Colors.orange;
          break;

        case 'leave':
          statusText = "Leave";
          statusBg = Colors.blue.shade100;
          statusColor = Colors.blue;
          break;

        case 'not punchin':
        case 'no punchin today':
          if (isToday) {
            statusText = "Not Punch In";
            statusBg = Colors.grey.shade200;
            statusColor = Colors.grey;
          } else {
            /// 🔥 PAST DAY → ABSENT
            statusText = "Absent";
            statusBg = Colors.red.shade100;
            statusColor = Colors.red;
          }
          break;

        case 'rejected':
        case 'absent':
        default:
          statusText = "Absent";
          statusBg = Colors.red.shade100;
          statusColor = Colors.red;
      }
    }

    Duration workedDuration = Duration.zero;

    if (punchIn != null && punchOut != null) {
      workedDuration = punchOut!.difference(punchIn!);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,

        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month),
          const SizedBox(width: 10),

          // Date Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}",
              ),
              const SizedBox(height: 4),
              Text(_weekDayName(date.weekday)),
            ],
          ),

          const Spacer(),

          // Time Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              punchIn != null
                  ? Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          TimeOfDay.fromDateTime(
                            punchIn!, // 🔥 IMPORTANT
                          ).format(context),
                        ),
                      ],
                    )
                  : const Text("-"),
              const SizedBox(height: 5),
              punchIn != null && punchOut != null
                  ? Text(
                      "${workedDuration.inHours}h ${workedDuration.inMinutes % 60}m",
                      style: const TextStyle(color: AppColors.royalblue),
                    )
                  : const SizedBox(),
            ],
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month];
  }

  String _weekDayName(int day) {
    const days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day];
  }
}
