import 'package:flutter/material.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/employees_attendance.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';

class EmployeeProfilePage extends StatefulWidget {
  final Map user;

  const EmployeeProfilePage({super.key, required this.user});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  bool showPassword = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name'] ?? "Employee"),
        backgroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade50,
                backgroundImage:
                    widget.user['profile_image_url'] != null &&
                        widget.user['profile_image_url'].toString().isNotEmpty
                    ? NetworkImage(widget.user['profile_image_url'])
                    : null,
                child:
                    widget.user['profile_image_url'] == null ||
                        widget.user['profile_image_url'].toString().isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.blue)
                    : null,
              ),

              SizedBox(height: size.height * 0.02),

              Text(
                widget.user['name'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              ListTile(
                leading: const Icon(Icons.assignment_ind_outlined),
                title: const Text("Employe ID"),
                subtitle: Text(widget.user['employee_id'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.business),
                title: const Text("Department"),
                subtitle: Text(widget.user['department'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.work),
                title: const Text("Role"),
                subtitle: Text((widget.user['role'] ?? "").toUpperCase()),
              ),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(widget.user['email'] ?? "No Email"),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Password"),
                subtitle: Text(
                  showPassword ? widget.user['password'] ?? "" : "••••••••",
                ),
                trailing: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Phone Number"),
                subtitle: Text(widget.user['phone'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Join Date"),
                subtitle: Text(widget.user['joining_date'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.bloodtype),
                title: const Text("Blood Group"),
                subtitle: Text(widget.user['blood_group'] ?? ""),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.shadowroyalblue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // keeps container size clean
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EmployeesAttendance(user: widget.user),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "View All",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.royalblue,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.royalblue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
