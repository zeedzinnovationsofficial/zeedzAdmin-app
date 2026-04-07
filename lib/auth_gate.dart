import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/onboarding_screen.dart';
import 'package:zeedz_attendance/dashboard_page.dart';
// import 'package:zeedz_attendance/User/home/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const Dashboard(currentindex: 0);
    } else {
      return OnboardingScreen();
    }
  }
}
