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
   Future.microtask(() async {
  await context.read<PunchProvider>().loadEmployees();
  await context.read<PunchProvider>().loadAllAttendance();
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
                final role = user['role'];
                 print("NET SALARY = ${user['net_salary']}");
                double salary = 0;

final joinDate = DateTime.parse(user['joining_date']);
final now = DateTime.now();

DateTime cycleStart = joinDate;

while (true) {
  final next = cycleStart.add(const Duration(days: 30));
  if (now.isBefore(next)) break;
  cycleStart = next;
}

final cycleEnd = cycleStart.add(const Duration(days: 29));

final employeeAttendance = punch.attendanceList.where((e) {
  if (e['user_id'] != user['id']) return false;

  final rowDate = DateTime.parse(e['date']);

  return !rowDate.isBefore(cycleStart) &&
      !rowDate.isAfter(cycleEnd);
});

for (var row in employeeAttendance) {
  salary += double.tryParse(
        row['earned_amount']?.toString() ?? "0",
      ) ??
      0;
}
double getSalaryByRole(String role) {
  switch (role) {
    case 'intern':
      return 3000;
    case 'hr':
      return 5000;
    case 'admin':
      return 8000;
    case 'super_admin':
      return 10000;
    default:
      return 4000;
  }
}

                return InkWell(
  borderRadius: BorderRadius.circular(24),
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
      horizontal: 16,
      vertical: 8,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),

    decoration: BoxDecoration(
      color:
          index % 5 == 0
              ? const Color(0xffE8F7F1)
              : index % 5 == 1
              ? const Color(0xffEAF6FF)
              : index % 5 == 2
              ? const Color(0xffF4EEFF)
              : index % 5 == 3
              ? const Color(0xffFFEFF5)
              : const Color(0xffFFF5E9),

      borderRadius: BorderRadius.circular(24),
    ),

    child: Row(
      children: [
        /// Profile
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          backgroundImage:
              user['profile_image_url'] != null &&
                      user['profile_image_url']
                          .toString()
                          .isNotEmpty
                  ? NetworkImage(user['profile_image_url'])
                  : null,

          child:
              user['profile_image_url'] == null ||
                      user['profile_image_url']
                          .toString()
                          .isEmpty
                  ? const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 30,
                  )
                  : null,
        ),

        const SizedBox(width: 16),

        /// Employee Details
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? "No Name",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                user['department'] ?? "",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 10),

              Row(
  children: [

    /// ROLE
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(30),
      ),

      child: Text(
        (user['role'] ?? '')
            .toUpperCase(),

        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,

          color:
              user['role'] == 'superadmin'
                  ? Colors.red
                  : user['role'] ==
                      'admin'
                  ? Colors.purple
                  : user['role'] == 'hr'
                  ? Colors.orange
                  : user['role'] ==
                      'intern'
                  ? Colors.blue
                  : Colors.green,
        ),
      ),
    ),

    const SizedBox(width: 8),

    /// NET SALARY
    Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  ),

  decoration: BoxDecoration(
    color: const Color(0xffEEF2FF),

    borderRadius: BorderRadius.circular(50),
  ),

  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.auto_graph_rounded,
        color: Color.fromARGB(255, 37, 30, 181),
        size: 16,
      ),

       SizedBox(width: 6),

      Text(
            "₹ ${salary.toStringAsFixed(0)}",

        style: const TextStyle(
          color: Color.fromARGB(255, 27, 19, 134),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  ),
)],
),],
          ),
        ),

        /// Right Side Buttons
        Column(
          children: [
            Container(
              height: 38,
              width: 38,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black54,
              ),
            ),

            
          ],
        ),
      ],
    ),
  ),
);},
            ),
    );
    
  }
  
}
