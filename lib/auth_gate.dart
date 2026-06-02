import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/onboarding_screen.dart';
import 'package:zeedz_attendance/dashboard_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    if (_initialized) return;

    final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
 await OneSignal.login(user.id);

await Future.delayed(const Duration(seconds: 5));
print("User ID = ${user.id}");
print("OneSignal ID = ${OneSignal.User.pushSubscription.id}");
print("Token = ${OneSignal.User.pushSubscription.token}");
print("OptedIn = ${OneSignal.User.pushSubscription.optedIn}");

final oneSignalId = OneSignal.User.pushSubscription.id;

print("ONESIGNAL ID = $oneSignalId");

if (oneSignalId != null && oneSignalId.isNotEmpty) {
  await Supabase.instance.client
      .from('users')
      .update({
        'onesignal_id': oneSignalId,
      })
      .eq('id', user.id);

  print("✅ SAVED TO SUPABASE");

  }

  final response = await Supabase.instance.client
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

  final role = response['role'];

  await OneSignal.User.addTags({
    "role": role.toString().toLowerCase(),
  });

  final tags = await OneSignal.User.getTags();

  print("TAGS = $tags");
}

    _initialized = true;
  }

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