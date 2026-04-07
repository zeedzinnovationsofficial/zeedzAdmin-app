import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class LeaveEmployeesPage extends StatefulWidget {
  final DateTime month;
  const LeaveEmployeesPage({super.key, required this.month});

  @override
  State<LeaveEmployeesPage> createState() => _LeaveEmployeesPageState();
}

class _LeaveEmployeesPageState extends State<LeaveEmployeesPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PunchProvider>().fetchLeaveList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    // GET CURRENT MONTH LEAVES
    List<Map<String, dynamic>> employees = [];

    for (final leave in punch.leaveList) {
      final start = DateTime.parse(leave['start_date']);
      final end = DateTime.parse(leave['end_date']);

      for (
        DateTime d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month == widget.month.month && d.year == widget.month.year) {
          employees.add({
            ...leave,
            'display_date': d.toIso8601String(), // 👈 important
          });
        }
      }
    }
    print(punch.leaveList);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees On Leave"),
        backgroundColor: AppColors.white,
      ),
      body: employees.isEmpty
          ? const Center(child: Text("No Leave Records This Month"))
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final user = employees[index];
                final leaveDate = DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(user['display_date']));
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  height: size.height * 0.14,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${index + 1}.",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.orange.shade50,
                        backgroundImage:
                            user['profile_image_url'] != null &&
                                user['profile_image_url'].toString().isNotEmpty
                            ? NetworkImage(user['profile_image_url'])
                            : null,
                        child:
                            (user['profile_image_url'] == null ||
                                user['profile_image_url'].toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.orange)
                            : null,
                      ),
                      SizedBox(width: size.width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user['users']?['name'] ?? "Employee",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: size.height * 0.0),
                            Text(
                              "Department: ${user['users']?['department'] ?? "Department"}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: size.height * 0.0),

                            // LEAVE DATE
                            Text(
                              "Date: $leaveDate",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),

                            SizedBox(height: size.height * 0.01),
                          Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: user['leave_type'] == 'paid'
        ? Colors.green.shade100
        : Colors.red.shade100,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    user['leave_type'] == 'paid'
        ? "PAID LEAVE"
        : "UNPAID LEAVE",
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: user['leave_type'] == 'paid'
          ? Colors.green
          : Colors.red,
    ),
  ),
),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
