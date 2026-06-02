import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/attendance/widget/leave_history.dart';
import 'package:zeedz_attendance/User/dailydata/widget/punch_detailcard_widget.dart';
import 'package:zeedz_attendance/User/dailydata/widget/punch_detailrow_widget.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/widget/dailydataskeleton.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/leavehistoryskeleton.dart';

class DailydataPage extends StatefulWidget {
  const DailydataPage({super.key});

  @override
  State<DailydataPage> createState() => _DailydataPageState();
}



class _DailydataPageState extends State<DailydataPage> {
  DateTime? startDate;
  DateTime? endDate;
Future<List<Map<String, dynamic>>>? leavesFuture;
Future<bool>? holidayFuture;
  @override
void initState() {
  super.initState();

  final provider = context.read<PunchProvider>();

  leavesFuture = provider.fetchMyLeaves();
  holidayFuture = checkIsHoliday();
}

  /// 🔥 CHECK HOLIDAY FROM DB
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
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    if (!punch.isLoaded) {
      return const Scaffold(
        body:DailyDataSkeleton(),
      );
    }

    return Scaffold(
       appBar: AppBar(
   
    title: Center(child: Text("Day Details",style:TextStyle(fontSize: 18,fontWeight: .bold) ,)),
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black,
  ),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<PunchProvider>();
          await provider.loadTodayPunch();

          setState(() {
            leavesFuture = provider.fetchMyLeaves();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.01),


              /// 🔥 STATUS CARD (FIXED LOGIC)
              FutureBuilder<bool>(
                future: checkIsHoliday(),
                builder: (context, snapshot) {
                  final isDbHoliday = snapshot.data ?? false;
                  final now = DateTime.now();

final cutoff = DateTime(
  now.year,
  now.month,
  now.day,
  11,
  0,
);

final isAfter11 =
    now.isAfter(cutoff) || now.isAtSameMomentAs(cutoff);

final hasPunchedIn =
    punch.inTime.isNotEmpty && punch.inTime != "--:--";

           String status;

final rawStatus = (punch.todayStatus ?? '').toLowerCase().trim();

if (rawStatus == "leave") {
  status = "leave";
}
else if (isDbHoliday) {
  status = "holiday";
}
/// 🔥 ABSENT MUST COME BEFORE APPROVED
else if (isAfter11 && !hasPunchedIn) {
  status = "absent";
}
else if (rawStatus == "approved") {
  status = "approved";
}
else if (rawStatus == "pending") {
  status = "pending";
}
else if (rawStatus == "rejected") {
  status = "rejected";
}
else {
  status = "not_punched";
}
                  Color bgColor = Colors.grey.shade200;
                  Color textColor = Colors.grey;
                  IconData icon = Icons.info_outline;
                  String statusText = "Not Punched In";

                 switch (status) {
  case 'approved':
    bgColor = AppColors.shadowgreen;
    textColor = AppColors.green;
    icon = Icons.check_circle_rounded;
    statusText = "Present";
    break;
 case 'pending':
    bgColor = Colors.orange.shade100;
    textColor = Colors.orange;
    icon = Icons.hourglass_empty;
    statusText = "Pending";
    break;
  case 'rejected':
    bgColor = AppColors.shadowred;
    textColor = AppColors.red;
    icon = Icons.cancel_rounded;
    statusText = "Absent";
    break;

  case 'leave':
    bgColor = AppColors.shadowroyalblue;
    textColor = AppColors.royalblue;
    icon = Icons.event_available;
    statusText = "On Leave";
    break;

  case 'holiday':
    bgColor = Colors.blue.shade100;
    textColor = Colors.blue;
    icon = Icons.celebration;
    statusText = "Holiday";
    break;
    case 'not_punched':
  bgColor = Colors.grey.shade200;
  textColor = Colors.grey;
  icon = Icons.info_outline;
  statusText = "Not Punched In";
  break;
  case 'absent':
  bgColor = AppColors.shadowred;
  textColor = AppColors.red;
  icon = Icons.cancel_rounded;
  statusText = "Absent";
  break;

 
    
}
return Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      height: size.height * 0.06,
                      width: size.width * 0.89,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: textColor),
                          SizedBox(width: size.width * 0.02),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: size.height * 0.02),

              Center(
                child: Text(
                  punch.todayFormatted,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              /// Punch Details
              PunchDetailrowWidget(
                leftCard: PunchDetailcardWidget(
                  icon: Icons.login,
                  circleColor: AppColors.shadowgreen,
                  iconColor: AppColors.green,
                  title: "Punch In",
                  time: punch.inTime.isEmpty ? "--:--" : punch.inTime,
                  location: punch.punchInLocation.isEmpty
    ? "--"
    : punch.punchInLocation,
                ),
                rightCard: PunchDetailcardWidget(
                  icon: Icons.logout,
                  circleColor: AppColors.shadowred,
                  iconColor: AppColors.red,
                  title: "Punch Out",
                  time: punch.outTime.isEmpty ? "--:--" : punch.outTime,
                 location: punch.punchOutLocation.isEmpty
    ? "--"
    : punch.punchOutLocation,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              /// Leave History Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Leave History",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: pickDateRange,
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.02),

              /// Leave History
              FutureBuilder<List<Map<String, dynamic>>>(
                future: leavesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                     return  LeaveHistorySkeleton();
                  }

                  final leaves = snapshot.data ?? [];

                  if (leaves.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.lightgrey, blurRadius: 2),
                        ],
                      ),
                      child: const Center(child: Text("No Leave Applied")),
                    );
                  }

                  return Column(
                    children: leaves.map((leave) {
                      Color statusColor =
                          leave['status'] == 'approved'
                              ? Colors.green
                              : leave['status'] == 'rejected'
                                  ? Colors.red
                                  : Colors.orange;

                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 110),
                          width: size.width * 0.9,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.lightgrey, blurRadius: 2),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
  builder: (context, constraints) {
    final reason = leave['reason'] ?? '--';
    final isLong = reason.toString().length > 45;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        bool expanded = false;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reason: $reason",
                  maxLines: expanded ? null : 2,
                  overflow:
                      expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (isLong)
                  GestureDetector(
                    onTap: () {
                      setStateSB(() {
                        expanded = !expanded;
                      });
                    },
                    child: Text(
                      expanded ? "See less" : "See more",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  },
),
                              const SizedBox(height: 5),
                              Text(
                                  "From: ${leave['start_date']}  To: ${leave['end_date']}"),
                              const SizedBox(height: 8),
                              Text(
                                "Status: ${leave['status']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: size.height * 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }
}
