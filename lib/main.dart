import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'package:zeedz_attendance/auth_gate.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/dashboard_page.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/resetpassword_page.dart';
import 'package:zeedz_attendance/service/realtime_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://zkgcjvricbdqbjdlaaan.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprZ2NqdnJpY2JkcWJqZGxhYWFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NjE2NzAsImV4cCI6MjA4NzEzNzY3MH0.fJcoCSoYPL_6Wd5OvvoucPdxdpwWZmdwJuAi0RCjVYY',
  );
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;

    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      );
    }
  });
  await Alarm.init();
  Alarm.ringStream.stream.listen((alarmSettings) async {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Dashboard(currentindex: 0)),
      (route) => false,
    );
  });

  /// 🔥 ONESIGNAL INIT
  await OneSignal.initialize("49cf1399-5699-48eb-ac39-7b487a6cc0e5");
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print("🔥 Foreground notification received");

    /// ❌ BLOCK notification inside chat page
    if (isChatPageOpen) {
      event.preventDefault(); // 🚫 don't show
      print("❌ Blocked (ChatPage open)");
    } else {
      event.notification.display(); // ✅ show normally
      print("✅ Notification shown");
    }
  });

  /// 🔔 ASK PERMISSION
  await OneSignal.Notifications.requestPermission(true);

  // 📱 get id
  await Future.delayed(const Duration(seconds: 5));

  final playerId = OneSignal.User.pushSubscription.id;

  print("🔥 OneSignal ID: $playerId");

  final user = Supabase.instance.client.auth.currentUser;

  if (user != null && playerId != null) {
    await Supabase.instance.client
        .from('users')
        .update({'onesignal_id': playerId})
        .eq('id', user.id);

    print("✅ OneSignal ID SAVED");
  }
  ;

  /// 🔄 REALTIME CHAT
  RealtimeService.start();
  runApp(const MyApp());
}

Future<void> saveOneSignalId() async {
  await Future.delayed(const Duration(seconds: 3));

  final playerId = OneSignal.User.pushSubscription.id;
  final user = Supabase.instance.client.auth.currentUser;

  print("🔥 OneSignal ID: $playerId");

  if (user != null && playerId != null) {
    await Supabase.instance.client
        .from('users')
        .update({'onesignal_id': playerId})
        .eq('id', user.id);

    print("✅ OneSignal ID SAVED");
  }
}

bool isAppInForeground = true;
bool isChatPageOpen = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isAppInForeground = true;
    } else {
      isAppInForeground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PunchProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: AppColors.white),
        home: const AuthGate(),
      ),
    );
  }
}
