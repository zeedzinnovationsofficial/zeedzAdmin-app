import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/AdminScreen/approval.dart';

import 'package:zeedz_attendance/AdminScreen/Leaveapproval/leave_approval_page.dart';
import 'package:zeedz_attendance/AdminScreen/employee_list_page.dart';
import 'package:zeedz_attendance/User/attendance/attendance_page.dart';
import 'package:zeedz_attendance/User/Leave/leave_page.dart';
import 'package:zeedz_attendance/User/dailydata/dailydata_page.dart';
import 'package:zeedz_attendance/User/home/home_page.dart';
import 'package:zeedz_attendance/User/profile/profile_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class Dashboard extends StatefulWidget {
  final int currentindex;
  const Dashboard({super.key, required this.currentindex});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.currentindex;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<PunchProvider>().role;

    List<Widget> screens;
    List<Map<String, dynamic>> navItems;

    ///  EMPLOYEE
    if (role == 'employee') {
      screens = [
        HomePage(),
        DailydataPage(),
        LeavePage(),
        AttendancePage(),
        ProfilePage(),
      ];

      navItems = [
        {"icon": Icons.home, "label": "Home"},
        {"icon": Icons.co_present_rounded, "label": "Dailydata"},
        {"icon": Icons.post_add, "label": "Leave"},
        {"icon": Icons.fact_check, "label": "Attendance"},
        {"icon": Icons.person, "label": "Profile"},
      ];
    }
    ///intern
    else if (role == 'intern') {
      screens = [
        HomePage(),
        DailydataPage(),
        LeavePage(),
        AttendancePage(),
        ProfilePage(),
      ];

      navItems = [
        {"icon": Icons.home, "label": "Home"},
        {"icon": Icons.co_present_rounded, "label": "Dailydata"},
        {"icon": Icons.post_add, "label": "Leave"},
        {"icon": Icons.fact_check, "label": "Attendance"},
        {"icon": Icons.person, "label": "Profile"},
      ];
    }
    ///  HR
    else if (role == 'hr') {
      screens = [
        HomePage(),
        DailydataPage(),
        AttendanceApproval(hasBottomNav: true),
        LeaveApprovalPage(),

        AttendancePage(),
      ];

      navItems = [
        {"icon": Icons.home, "label": "Home"},
        {"icon": Icons.co_present_rounded, "label": "Dailydata"},
        {"icon": Icons.approval_outlined, "label": "Approval"},
        {"icon": Icons.verified_outlined, "label": "Leaves"},

        {"icon": Icons.fact_check, "label": "Attendance"},
      ];
    }
    ///  ADMIN
    else if (role == 'admin') {
      screens = [
        HomePage(),
        DailydataPage(),
        AttendanceApproval(hasBottomNav: true),
        LeaveApprovalPage(),

        AttendancePage(),
      ];

      navItems = [
        {"icon": Icons.home, "label": "Home"},
        {"icon": Icons.co_present_rounded, "label": "Dailydata"},
        {"icon": Icons.approval_outlined, "label": "Approval"},
        {"icon": Icons.verified_outlined, "label": "Leaves"},

        {"icon": Icons.fact_check, "label": "Attendance"},
      ];
    }
    /// superadmin
    else {
      screens = [
        HomePage(),
        AttendanceApproval(hasBottomNav: true),
        LeaveApprovalPage(),
        EmployeeListPage(),
      ];

      navItems = [
        {"icon": Icons.home, "label": "Home"},
        {"icon": Icons.approval_outlined, "label": "Approval"},
        {"icon": Icons.verified_outlined, "label": "Leaves"},
        {"icon": Icons.admin_panel_settings, "label": "Employees"},
      ];
    }

    if (selectedIndex >= screens.length) {
      selectedIndex = 0;
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: selectedIndex, children: screens),
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                ],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  return NavItem(
                    navItems[index]["icon"],
                    navItems[index]["label"],
                    onTap: () async {
                      print("TAB CLICKED: $index");
                      setState(() => selectedIndex = index);

                      //  Refresh data when switching tabs
                      // await context.read<PunchProvider>().refreshAll();
                    },
                    isSelected: selectedIndex == index,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem(
    this.icon,
    this.label, {
    super.key,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.black : Colors.grey,
            size: 26,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
