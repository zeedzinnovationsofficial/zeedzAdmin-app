import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeedz_attendance/dashboard_page.dart';

import 'login_page.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();

    isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isLoggedIn!) {
      return const Dashboard(currentindex: 0);
    }

    return const LoginPage();
  }
}
