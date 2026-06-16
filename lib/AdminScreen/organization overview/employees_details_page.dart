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
DateTime getCycleStart(DateTime joiningDate, DateTime now) {
  DateTime start = joiningDate;

  while (true) {
    final next = DateTime(
      start.year,
      start.month + 1,
      start.day,
    );

    if (now.isBefore(next)) break;

    start = next;
  }

  return start;
}

DateTime getCycleEnd(DateTime cycleStart) {
  return DateTime(
    cycleStart.year,
    cycleStart.month + 1,
    cycleStart.day - 1,
  );
}
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
                final userId = user['id'];
final netSalary = punch.getCurrentMonthNetSalary(userId);
                final role = user['role'];
                 print("NET SALARY = ${user['net_salary']}");
              



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
  "₹ ${netSalary.toStringAsFixed(0)}",

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
