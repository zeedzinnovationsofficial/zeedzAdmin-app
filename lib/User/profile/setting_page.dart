import 'package:flutter/material.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/profile/alarm_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool notificationEnabled = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: size.height * 0.01),

          Container(
            padding: EdgeInsets.all(12),
            height: size.height * 0.09,
            width: size.width * 0.3,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightgrey,
                  blurRadius: 2,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications,
                color: AppColors.royalblue,
              ),
              title: const Text("Notifications"),
              value: notificationEnabled,
              onChanged: (value) {
                setState(() {
                  notificationEnabled = value;
                });
              },
            ),
          ),
          SizedBox(height: size.height * 0.01),

          Container(
            padding: EdgeInsets.all(12),
            height: size.height * 0.09,
            width: size.width * 0.3,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightgrey,
                  blurRadius: 2,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: buildTile(
              icon: Icons.alarm,
              title: "Set Alarm",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlarmPage()),
                );
              },
            ),
          ),

          // SizedBox(height: size.height * 0.01),
          // Container(
          //   padding: EdgeInsets.all(12),
          //   height: size.height * 0.07,
          //   width: size.width * 0.3,
          //   decoration: BoxDecoration(
          //     color: AppColors.white,
          //     borderRadius: BorderRadius.circular(10),
          //     boxShadow: [
          //       BoxShadow(
          //         color: AppColors.lightgrey,
          //         blurRadius: 2,
          //         offset: Offset(0, 0),
          //       ),
          //     ],
          //   ),
          //   child: buildTile(
          //     icon: Icons.lock,
          //     title: "Change Password",
          //     onTap: () {},
          //   ),
          // ),
          // SizedBox(height: size.height * 0.01),
          // Container(
          //   padding: EdgeInsets.all(12),
          //   height: size.height * 0.07,
          //   width: size.width * 0.3,
          //   decoration: BoxDecoration(
          //     color: AppColors.white,
          //     borderRadius: BorderRadius.circular(10),
          //     boxShadow: [
          //       BoxShadow(
          //         color: AppColors.lightgrey,
          //         blurRadius: 2,
          //         offset: Offset(0, 0),
          //       ),
          //     ],
          //   ),
          //   child: buildTile(
          //     icon: Icons.location_on,
          //     title: "Location Permission",
          //     onTap: () {},
          //   ),
          // ),
          SizedBox(height: size.height * 0.01),
        ],
      ),
    );
  }

  Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.royalblue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
