import 'package:flutter/material.dart';
import 'package:zeedz_attendance/AdminScreen/employee_salary_page.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/employees_attendance.dart';



class EmployeeDetailsTab extends StatelessWidget {
  final Map<String, dynamic> user;

  const EmployeeDetailsTab({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user['name'] ?? "Employee"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Attendance"),
              Tab(text: "Salary"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            EmployeesAttendance(user: user),

            EmployeeSalaryPage(
              employeeId: user['id'],
            ),
          ],
        ),
      ),
    );
  }
}