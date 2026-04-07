import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class PresentEmployeesPage extends StatelessWidget {
  const PresentEmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    final employees = punch.todayPresentEmployeesList;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Present Employees"),
        backgroundColor: AppColors.white,
      ),
      body: employees.isEmpty
          ? const Center(child: Text("No Employees Present Today"))
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final user = employees[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  height: size.height * 0.12,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.lightgrey,
                        blurRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// Profile Circle
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.green.shade50,
                        child:
                            const Icon(Icons.person, color: Colors.green),
                      ),

                      const SizedBox(width: 15),

                      /// User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              user['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Department: ${user['department'] ?? ''}",
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 8),

                            /// Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "PRESENT",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
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