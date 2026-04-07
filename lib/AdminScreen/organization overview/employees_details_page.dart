import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/employees_profile_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class EmployeesDetailsPage extends StatefulWidget {
  final DateTime? month;
  const EmployeesDetailsPage({super.key, this.month});

  @override
  State<EmployeesDetailsPage> createState() => _EmployeesDetailsPageState();
}

class _EmployeesDetailsPageState extends State<EmployeesDetailsPage> {
  String selectedRole = "All";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PunchProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();

    final filteredEmployees = punch.employeeList.where((user) {
      final joinDate = DateTime.parse(user['joining_date']);

      // ✅ if month is passed → filter
      if (widget.month != null) {
        final endOfMonth = DateTime(
          widget.month!.year,
          widget.month!.month + 1,
          0,
        );

        if (joinDate.isAfter(endOfMonth)) return false;
      }

      // ✅ department filter
      if (selectedRole != "All" && user['role'] != selectedRole) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
        backgroundColor: AppColors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRole,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All")),
                  DropdownMenuItem(
                    value: "superadmin",
                    child: Text("Super Admin"),
                  ),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "hr", child: Text("HR")),
                  DropdownMenuItem(value: "employee", child: Text("Employee")),
                  DropdownMenuItem(value: "intern", child: Text("Intern")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: filteredEmployees.isEmpty
          ? const Center(
              child: Text(
                "No Employees Found",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final user = filteredEmployees[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeProfilePage(user: user),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    height: size.height * 0.12,
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
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),

                        /// Profile
                        CircleAvatar(
                          radius: size.width * 0.06,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              user['profile_image_url'] != null &&
                                  user['profile_image_url']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(user['profile_image_url'])
                              : null,
                          child:
                              user['profile_image_url'] == null ||
                                  user['profile_image_url'].toString().isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),

                        SizedBox(width: size.width * 0.04),

                        /// Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              SizedBox(height: size.height * 0.0),

                              Text(
                                "Department: ${user['department'] ?? ''}",
                                style: const TextStyle(color: Colors.grey),
                              ),

                              SizedBox(height: size.height * 0.01),

                              /// Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user['role'] == 'superadmin'
                                      ? Colors.red.shade100
                                      : user['role'] == 'admin'
                                      ? Colors.purple.shade100
                                      : user['role'] == 'hr'
                                      ? Colors.orange.shade100
                                      : user['role'] == 'intern'
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (user['role'] ?? '').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: user['role'] == 'superadmin'
                                        ? Colors.red
                                        : user['role'] == 'admin'
                                        ? Colors.purple
                                        : user['role'] == 'hr'
                                        ? Colors.orange
                                        : user['role'] == 'intern'
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
