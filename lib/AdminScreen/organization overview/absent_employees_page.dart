import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class AbsentEmployeesPage extends StatefulWidget {
  final DateTime month;
  const AbsentEmployeesPage({super.key, required this.month});

  @override
  State<AbsentEmployeesPage> createState() => _AbsentEmployeesPageState();
}

class _AbsentEmployeesPageState extends State<AbsentEmployeesPage> {
 
// @override
// void initState() {
//   super.initState();

//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     final punch = context.read<PunchProvider>();

//  await punch.loadStatsByMonth(widget.month);
//   });
// }
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
  final punch = context.read<PunchProvider>();
    print(punch.getMonthAbsentEmployees(widget.month));
  
   final employees = List<Map<String, dynamic>>.from(
  punch.getMonthAbsentEmployees(widget.month),
);

employees.sort((a, b) {
  final dateA = DateTime.parse(a['date']);
  final dateB = DateTime.parse(b['date']);

  return dateB.compareTo(dateA); // latest first
});
    return Scaffold(
      appBar: AppBar(
        title: const Text("Absent Employees"),
        backgroundColor: AppColors.white,
      ),
      body: employees.isEmpty
          ? const Center(child: Text("No Absent Employees This Month"))
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final user = employees[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  height: size.height * 0.122,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                    ],
                  ),
                  child: Stack(
                    children: [
                      /// ABSENT DATE TOP RIGHT
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Text(
                          user['date'] != null
                              ? DateFormat(
                                  'dd MMM',
                                ).format(DateTime.parse(user['date']))
                              : '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Text(
                            "${index + 1}.",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.red,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: size.width * 0.04),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.red.shade50,
                            backgroundImage:
                                user['profile_image_url'] != null &&
                                    user['profile_image_url']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(user['profile_image_url'])
                                : null,
                            child:
                                (user['profile_image_url'] == null ||
                                    user['profile_image_url']
                                        .toString()
                                        .isEmpty)
                                ? const Icon(Icons.person, color: Colors.red)
                                : null,
                          ),
                          SizedBox(width: size.width * 0.04),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                SizedBox(width: size.width * 0.04),

                                Text(
                                  "Department: ${user['department'] ?? ''}",
                                  style: const TextStyle(color: Colors.grey),
                                ),

                                SizedBox(height: size.height * 0.01),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "ABSENT",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
