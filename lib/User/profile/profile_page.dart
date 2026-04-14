import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/AdminScreen/employee_list_page.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/employees_details_page.dart';
import 'package:zeedz_attendance/User/Leave/leave_page.dart';
import 'package:zeedz_attendance/User/dailydata/dailydata_page.dart';
import 'package:zeedz_attendance/User/home/login_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/profile/setting_page.dart';
import 'package:zeedz_attendance/User/profile/widget/holiday_page.dart';
import 'package:zeedz_attendance/User/profile/widget/profile_details.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PunchProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    buildTile(
      icon: Icons.calendar_today,
      title: "Leave Balance",
      value: "${punch.leaveBalance} Days",
      context: context,
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.07),
            Row(
              children: [
                if (punch.role == 'hr' ||
                    punch.role == 'admin' ||
                    punch.role == 'superadmin')
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                else
                  SizedBox(width: size.width * 0.1),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.08), // balance spacing
              ],
            ),
            SizedBox(height: size.height * 0.018),

            ///  PROFILE CARD
            const ProfileDetails(),

            SizedBox(height: size.height * 0.018),

            const Text(
              "Contact Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: size.height * 0.015),

            /// EMAIL
            buildTile(
              icon: Icons.mail,
              title: "Email",
              value: user?.email ?? "No Email",
              context: context,
            ),
           

            /// PHONE
            buildTile(
              icon: Icons.phone_in_talk,
              title: "Phone No",
              value: punch.phone.isEmpty ? "--" : punch.phone,
              context: context,
            ),

            /// JOIN DATE
            buildTile(
              icon: Icons.calendar_month_rounded,
              title: "Join Date",
              value: punch.joiningDate.isEmpty ? "--" : punch.joiningDate,
              context: context,
            ),

            if (punch.role == 'hr' ||
                punch.role == 'admin' ||
                punch.role == 'superadmin') ...[
              SizedBox(height: size.height * 0.0),

              /// Add Employee
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeListPage()),
                  );
                },
                child: buildTile(
                  icon: Icons.person_add,
                  title: "Add Employees",
                  value: "",
                  isClickable: true,
                  context: context,
                ),
              ),

              SizedBox(height: size.height * 0.0),


              SizedBox(height: size.height * 0.0),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmployeesDetailsPage()),
                  );
                },
                child: buildTile(
                  icon: Icons.document_scanner_outlined,
                  title: "Employees Details",
                  value: "",
                  isClickable: true,
                  context: context,
                ),
              ),
              SizedBox(height: size.height * 0.0),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HolidayPage()),
                  );
                },
                child: buildTile(
                  icon: Icons.event_available,
                  title: "provide Holiday",
                  value: "",
                  isClickable: true,
                  context: context,
                ),
              ),
               InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DailydataPage()),
                  );
                },
                child: buildTile(
                  icon: Icons.co_present_rounded,
                  title: "Dailydata",
                  value: "",
                  isClickable: true,
                  context: context,
                ),
              ),
            ],

            SizedBox(height: size.height * 0.0),

              /// Leave Applying
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LeavePage()),
                  );
                },
                child: buildTile(
                  icon: Icons.post_add,
                  title: "Leave Applying",
                  value: "",
                  isClickable: true,
                  context: context,
                ),
              ),
            /// SETTINGS
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingPage()),
                );
              },
              child: buildTile(
                icon: Icons.settings,
                title: "Setting",
                value: "",
                isClickable: true,
                context: context,
              ),
            ),

            SizedBox(height: size.height * 0.004),

            /// SETTINGS
            GestureDetector(
              onTap: () async {
                final provider = context.read<PunchProvider>();

                await Supabase.instance.client.auth.signOut();
                provider.resetData();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                height: size.height * 0.07,
                width: size.width * 0.89,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: size.height * 0.2),
          ],
        ),
      ),
    );
  }

  Widget buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    bool isClickable = false,
  }) {
    final size = MediaQuery.of(context).size;
    final isValueEmpty = value.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      height: size.height * 0.0822,
      width: size.width * 0.89,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
      ),
      child: Row(
        children: [
          /// ICON
          Icon(icon, color: AppColors.royalblue),

          const SizedBox(width: 12),

          /// 🔥 CONDITIONAL UI
          Expanded(
            child: isValueEmpty
                ? Text(title, style: const TextStyle(fontSize: 15))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title),
                      const SizedBox(height: 4),
                      Text(value),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
