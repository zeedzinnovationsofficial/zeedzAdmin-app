import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/dailydata/widget/punch_detailcard_widget.dart';
import 'package:zeedz_attendance/User/dailydata/widget/punch_detailrow_widget.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class DailydataPage extends StatefulWidget {
  const DailydataPage({super.key});

  @override
  State<DailydataPage> createState() => _DailydataPageState();
}

late Future<List<Map<String, dynamic>>> leavesFuture;

class _DailydataPageState extends State<DailydataPage> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();

    final provider = context.read<PunchProvider>();

    leavesFuture = provider.fetchMyLeaves();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    if (!punch.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<PunchProvider>();

          await provider.loadTodayPunch();

          setState(() {
            leavesFuture = provider.fetchMyLeaves(); // ✅ refresh manually
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.06),

              const Center(
                child: Text(
                  "Day Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: size.height * 0.018),

              /// Present / Absent Card
              Builder(
                builder: (context) {
                  String status = punch.todayStatus ?? 'pending';

                  Color bgColor;
                  Color textColor;
                  IconData icon;
                  String statusText;

                  switch (status) {
                    case 'approved':
                      bgColor = AppColors.shadowgreen;
                      textColor = AppColors.green;
                      icon = Icons.check_circle_rounded;
                      statusText = "Present";
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

                    default:
                      if (punch.punchInTime == null) {
                        bgColor = Colors.grey.shade200;
                        textColor = Colors.grey;
                        icon = Icons.info_outline;
                        statusText = "Not Punched In";
                      } else {
                        bgColor = Colors.orange.shade100;
                        textColor = Colors.orange;
                        icon = Icons.hourglass_empty;
                        statusText = "Pending";
                      }
                  }

                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(9),
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
                  location: punch.locationAddress.isEmpty
                      ? "--"
                      : punch.locationAddress,
                ),
                rightCard: PunchDetailcardWidget(
                  icon: Icons.logout,
                  circleColor: AppColors.shadowred,
                  iconColor: AppColors.red,
                  title: "Punch Out",
                  time: punch.outTime.isEmpty ? "--:--" : punch.outTime,
                  location: punch.locationAddress.isEmpty
                      ? "--"
                      : punch.locationAddress,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              /// Leave History Title + Calendar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Leave History",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: pickDateRange,
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.02),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: leavesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final leaves = snapshot.data ?? [];

                  /// DATE FILTER
                  List<Map<String, dynamic>> filteredLeaves = leaves;

                  if (startDate != null && endDate != null) {
                    filteredLeaves = leaves.where((leave) {
                      final start = DateTime.parse(leave['start_date']);
                      final end = DateTime.parse(leave['end_date']);

                      return start.isBefore(
                            endDate!.add(const Duration(days: 1)),
                          ) &&
                          end.isAfter(
                            startDate!.subtract(const Duration(days: 1)),
                          );
                    }).toList();
                  }

                  if (filteredLeaves.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                        ],
                      ),
                      child: const Center(child: Text("No Leave Applied")),
                    );
                  }

                  return Column(
                    children: filteredLeaves.map((leave) {
                      Color statusColor;

                      if (leave['status'] == 'approved') {
                        statusColor = Colors.green;
                      } else if (leave['status'] == 'rejected') {
                        statusColor = Colors.red;
                      } else {
                        statusColor = Colors.orange;
                      }

                      return Center(
                        child: Container(
                          height: size.height * 0.19,
                          width: size.width * 0.9,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lightgrey,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Reason: ${leave['reason'] ?? '--'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),

                              Text(
                                "From: ${leave['start_date']}  To: ${leave['end_date']}",
                              ),
                              const SizedBox(height: 8),

                              Text(
                                "Status: ${leave['status']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  fontSize: 14,
                                ),
                              ),
                              if (leave['status'] == 'approved')
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: leave['leave_type'] == 'paid'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      leave['leave_type'] == 'paid'
                                          ? "Paid Leave"
                                          : "Unpaid Leave",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: leave['leave_type'] == 'paid'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              if (leave['status'] == 'rejected' &&
                                  leave['reject_reason'] != null &&
                                  leave['reject_reason'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Rejected Reason: ${leave['reject_reason']}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
