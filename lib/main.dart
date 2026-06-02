import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/auth_gate.dart'; 
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/dashboard_page.dart';
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/resetpassword_page.dart';
import 'package:zeedz_attendance/service/realtime_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("🔔 Background Message: ${message.notification?.title}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  const isProd = bool.fromEnvironment('dart.vm.product');

 final supabaseUrl = dotenv.env['PROD_SUPABASE_URL'];
final supabaseKey = dotenv.env['PROD_SUPABASE_ANON_KEY'];

  /// ADD HERE
  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception("❌ Missing Supabase ENV values");
  }

  ///  DEBUG PRINT
 print("🔥 ENV: PROD");
print("🌐 URL: $supabaseUrl");

  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

// 🔔 Notification permission
await messaging.requestPermission();

// 🔥 Background notification
FirebaseMessaging.onBackgroundMessage(
  _firebaseMessagingBackgroundHandler,
);

// 📱 Get FCM token
String? token = await messaging.getToken();

print("🔥 FCM TOKEN: $token");

  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseKey!);
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

await OneSignal.initialize("ae86ab43-3a9b-4c7a-92c2-831be9a91ad9");

await OneSignal.Notifications.requestPermission(true);
final user = Supabase.instance.client.auth.currentUser;


if (user != null) {
  OneSignal.User.addTagWithKey(
    "user_id",
    user.id,
  );
}
await Future.delayed(const Duration(seconds: 5));


print("OneSignal ID = ${OneSignal.User.pushSubscription.id}");
print("OneSignal Token = ${OneSignal.User.pushSubscription.token}");
print("OneSignal OptedIn = ${OneSignal.User.pushSubscription.optedIn}");



OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  if (isChatPageOpen) {
    event.preventDefault();
  } else {
    event.notification.display();
  }
});

/// 📡 LISTENER (OK HERE)
OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  print("🔥 Foreground notification received");

  if (isChatPageOpen) {
    event.preventDefault();
  } else {
    event.notification.display();
  }
});

 



OneSignal.User.pushSubscription.addObserver((state) async {
  final playerId = state.current.id;

  if (playerId == null || playerId.isEmpty) {
    print("Subscription not ready");
    return;
  }

  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) return;

  await Supabase.instance.client
      .from('users')
      .update({
        'onesignal_id': playerId,
      })
      .eq('id', user.id);

  print("✅ OneSignal ID SAVED: $playerId");
});
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
       theme: ThemeData(
  scaffoldBackgroundColor: AppColors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
  ),
),
        home: const AuthGate(),
      ),
    );
  }
}
