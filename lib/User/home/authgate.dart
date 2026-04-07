import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/login_page.dart';
import 'package:zeedz_attendance/dashboard_page.dart';

import 'package:zeedz_attendance/provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        // After login → load today's punch
        Future.microtask(() {
          context.read<PunchProvider>().loadTodayPunch();
        });

        return const Dashboard(currentindex: 0,);
      },
    );
  }
}