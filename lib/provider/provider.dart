import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class PunchProvider extends ChangeNotifier {
  
  PunchProvider() {}
  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> employeeList = [];
  List<Map<String, dynamic>> todayAttendance = [];
  List<String> todayLeaveUserIds = [];
  List<Map<String, dynamic>> leaveList = [];
  List<Map<String, dynamic>> filteredAttendance = [];
   double _calculateDistance(List<double> a, List<double> b) {
    double sum = 0;

    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return sqrt(sum);
  }



  final supabase = Supabase.instance.client;

  // STATE
  DateTime? currentStartDate;
  DateTime? currentEndDate;
  DateTime? punchInTime;
  DateTime? punchOutTime;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool isRunning = false;
  String punchStatus = "in";
  bool _isLoadingStats = false;

  String get inTime {
    if (punchInTime == null) return "--:--";
    return DateFormat('hh:mm a').format(punchInTime!);
  }

  String get outTime {
    if (punchOutTime == null) return "--:--";
    return DateFormat('hh:mm a').format(punchOutTime!);
  }
  

  String statusText = "Not Punched";
 
  String photoUrl = '';
String punchInLocation = "--";
String punchOutLocation = "--";
  String userEmail = "";

  bool isLoaded = false;
  Timer? _midnightTimer;
  String name = "";
  String phone = "";
  String department = "";
  String joiningDate = "";
  String workSchedule = "mon_fri";

  String profileImageUrl = '';
  String? employeeId;
  String role = 'employee';
  String email = '';
  String? todayStatus;
  int monthlyLeaveDays = 0;
  int _statsRequestId = 0;
List<DateTime> holidays = [];
Map<String, String> holidayReasons = {};
  // Leave Data
  DateTime? startDate;
  DateTime? endDate;
int get totalPendingEmployeesToday =>
    todayPendingEmployeesList.length;
  int totalLeaveDays = 0;
  int leaveBalance = 0;
  int pendingCount = 0; 
  String _reason = '';

  String get reason => _reason;

  void setReason(String value) {
    _reason = value;
  }

  void setStartDate(DateTime date) {
    startDate = date;
    calculateDays();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    calculateDays();
    notifyListeners();
  }

  void calculateDays() {
    if (startDate != null && endDate != null) {
      totalLeaveDays = endDate!.difference(startDate!).inDays + 1;
      notifyListeners();
    }
  }

  void listenAttendanceChanges() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    supabase.from('attendance').stream(primaryKey: ['id']).listen((
      event,
    ) async {
      await loadAttendance(); //  refresh monthly list
      await loadTodayPunch(); // refresh today
      await loadMonthlyLeaveCount(); // refresh leave
      await loadAllPendingCount();
      await loadTodayLeave();
      notifyListeners();
    });
  }
  

  // Future<void> refreshAll() async {
  //   await loadAttendance();
  //   await loadTodayPunch();
  //   await loadMonthlyLeaveCount();

  //   notifyListeners();
  // }
  //leave date
  
Future<void> loadLeavePageData() async {
  await fetchLeaveList(); // ONLY THIS
}

    Future<void> initializeApp() async {
  try {
    await loadProfile();
    await loadHolidays();
   
    await loadTodayPunch();
    await loadMonthlyLeaveCount();
   
    await loadEmployees();
    await loadTodayLeave();
  
    await loadAllPendingCount();

  await loadAllAttendance(); // ADD THIS
await loadTodayAllAttendance(); // ADD THIS
    if (role == 'superadmin' || role == 'admin' || role == 'hr') {
      await loadSuperAdminStats();
    }

  
    listenAttendanceChanges();
  } catch (e) {
    print("INIT ERROR: $e");
  } finally {
    isLoaded = true;
    notifyListeners();
  }
}
Future<void> loadAllPendingCount() async {
  final now = DateTime.now();

  final startOfMonth =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

  final today =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  final response = await supabase
      .from('attendance')
      .select('id')
      .eq('status', 'pending')
      .gte('date', startOfMonth)
      .lte('date', today);

  pendingCount = response.length; // counts every pending record

  print("MONTH TOTAL PENDING: $pendingCount");

  notifyListeners();
}
  Future<void> loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("No logged in user");
      return;
    }

    try {
      print("Auth UID: ${user.id}");

      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single(); // use single for strict check

      print("Raw DB Data: $data");

      // Assign values
      name = data['name'] ?? '';
      phone = data['phone'] ?? '';
      department = data['department'] ?? '';
      joiningDate = data['joining_date']?.toString() ?? '';
      profileImageUrl = data['profile_image_url'] ?? '';
      role = data['role'] ?? '';
      employeeId = data['employee_id'];
      email = data['email'] ?? '';
      leaveBalance = data['leave_balance'] ?? 0;
      workSchedule = data['work_schedule'] ?? "mon_fri";
      print("Loaded role: $role");

      notifyListeners();
    } catch (e) {
      print("Error loading profile: $e");
    }
  }
Future<void> saveAbsentAndLeaveForToday() async {
  print("saveAbsentAndLeaveForToday called");

  final now = DateTime.now();

if (now.weekday == DateTime.sunday) {
  return;
}

if (isHoliday(now)) {
  return;
}

  // ✅ Only after 11:00 AM
  final cutoff = DateTime(now.year, now.month, now.day, 11, 0);
  if (now.isBefore(cutoff)) {
    print("Before 11 AM → skip absent marking");
    return;
  }

  final dateStr = DateFormat('yyyy-MM-dd').format(now);

 final users = await supabase
    .from('users')
    .select('id, role')
    .neq('role', 'superadmin');

 for (final user in users) {
  final userId = user['id'];
  final userRole = (user['role'] ?? '').toString().toLowerCase();
    // ✅ GET USER WORK SCHEDULE
  final userData = await supabase
      .from('users')
      .select('work_schedule')
      .eq('id', userId)
      .single();

  final workSchedule =
      (userData['work_schedule'] ?? 'mon_sat').toString();

  // ✅ SKIP SUNDAY
  if (workSchedule == 'mon_sat' &&
      now.weekday == DateTime.sunday) {
    continue;
  }

  // ✅ SKIP SATURDAY + SUNDAY
  if (workSchedule == 'mon_fri' &&
      (now.weekday == DateTime.saturday ||
       now.weekday == DateTime.sunday)) {
    continue;
  }

  // check attendance exists
  final attendance = await supabase
      .from('attendance')
      .select('id')
      .eq('user_id', userId)
      .eq('date', dateStr)
      .maybeSingle();

  if (attendance != null) continue;

  // check leave
  final leave = await supabase
      .from('leave_requests')
      .select('id')
      .eq('user_id', userId)
      .eq('status', 'approved')
      .lte('start_date', dateStr)
      .gte('end_date', dateStr)
      .maybeSingle();

  int deduction = 0;

  if (leave == null) {
    switch (userRole) {
      case 'intern':
        deduction = 3000 ~/ 30;
        break;
      case 'employee':
        deduction = 4000 ~/ 30;
        break;
      case 'hr':
        deduction = 5000 ~/ 30;
        break;
      case 'admin':
        deduction = 8000 ~/ 30;
        break;
      default:
        deduction = 0;
    }
  }

  await supabase.from('attendance').upsert({
    'user_id': userId,
    'date': dateStr,
    'status': leave != null ? 'leave' : 'absent',
    'earned_amount': 0,
    'deductions': deduction,
  });
}
  await loadAllAttendance();
  await loadTodayAllAttendance();
  notifyListeners();
}
Future<void> punchIn(String location, BuildContext context) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final dateOnly = DateFormat('yyyy-MM-dd').format(now);

  try {
    // Holiday check
    if (isHoliday(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Today is ${getHolidayReason(now)}")),
      );
      return;
    }

    // Prevent duplicate punch
   final record = await supabase
    .from('attendance')
    .select()
    .eq('user_id', user.id)
    .eq('date', dateOnly)
    .maybeSingle();

print("RECORD: $record");
print("STATUS: $punchStatus");

if (record != null &&
    record['punch_in'] != null &&
    record['punch_out'] == null &&
    record['status'] != 'rejected') {
 
  return;
}

    // Insert punch
  await supabase.from('attendance').upsert({
  'user_id': user.id,
  'date': dateOnly,
  'punch_in': now.toIso8601String(),
  'punch_in_location': location, // ✅ only IN location
  'status': 'pending',
  'earned_amount': 0,
  'deductions': 0,
}, onConflict: 'user_id,date');

final check = await supabase
    .from('attendance')
    .select('status')
    .eq('user_id', user.id)
    .eq('date', dateOnly)
    .single();

print("AFTER PUNCH STATUS: ${check['status']}");

    // Update UI
    punchInTime = now;
punchStatus = "out";
statusText = "Punched In";
punchInLocation = location;

    await loadTodayPunch();
    await loadAttendance();
    await loadAllPendingCount();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Punch In Successful ✅")),
    );

    notifyListeners();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
Future<void> loadTodayAllAttendance() async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final response = await supabase
      .from('attendance')
      .select('user_id, status, punch_in')
      .eq('date', today);

  todayAttendance = List<Map<String, dynamic>>.from(response);

  print("TODAY ALL ATTENDANCE: ${todayAttendance.length}");

  notifyListeners();
}

Future<void> punchOut({
  required String location,
  required BuildContext context,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final today = DateTime.now().toIso8601String().split("T")[0];

  try {
    /// ✅ ONLY UPDATE punch_out
  final record = await supabase
    .from('attendance')
    .select('id, punch_out')
    .eq('user_id', user.id)
    .eq('date', today)
    .maybeSingle();

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No punch-in found today")),
      );
      return;
    }

    if (record['punch_out'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already punched out")),
      );
      return;
    }

 


await supabase.from('attendance').update({
  'punch_out': DateTime.now().toIso8601String(),
  'punch_out_location': location,
}).eq('id', record['id']);

    punchOutTime = DateTime.now();

    await loadTodayPunch();
    await loadAttendance();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Punch Out Successful ✅")),
    );

    notifyListeners();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}Future<void> loadTodayPunch() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);


  final leaveToday = await supabase
      .from('leave_requests')
      .select()
      .eq('user_id', user.id)
      .eq('status', 'approved')
      .lte('start_date', today)
      .gte('end_date', today)
      .maybeSingle();

  if (leaveToday != null) {
    todayStatus = 'leave';
    punchStatus = "leave";
    statusText = "On Leave";
    notifyListeners();
    return;
  }

  final holidayRes = await supabase
      .from('holidays')
      .select()
      .eq('holiday_date', today);

  if (holidayRes.isNotEmpty) {
    todayStatus = "holiday";
    punchStatus = "holiday";
    statusText = "Holiday";
    notifyListeners();
    return;
  }

  final data = await supabase
      .from('attendance')
        .select('punch_in, punch_out, punch_in_location, punch_out_location, status')
      .eq('user_id', user.id)
      .eq('date', today)
      .maybeSingle();
      if (data == null) {
  punchInTime = null;
  punchOutTime = null;
  isRunning = false;
  punchStatus = "in";
  statusText = "Punch In";
  todayStatus = "";
  punchInLocation = "--";
  punchOutLocation = "--";
}

 if (data != null) {
  todayStatus = data['status'];
punchInLocation = data['punch_in_location'] ?? "--";
punchOutLocation = data['punch_out_location'] ?? "--";

if (data['punch_in'] != null) {
  punchInTime = DateTime.parse(data['punch_in']);
}

if (data['punch_out'] != null) {
  punchOutTime = DateTime.parse(data['punch_out']);
}
  // ✅ Correct order
  if (todayStatus == 'leave') {
    punchStatus = "leave";
    statusText = "On Leave";
    isRunning = false;
  } 
  else if (todayStatus == 'rejected') {
    punchStatus = "absent";
    statusText = "Absent";
    isRunning = false;
  }
  else if (punchInTime != null && punchOutTime == null) {
    punchStatus = "out";
    statusText = "Working";
    isRunning = true;
  } 
  else if (punchInTime != null && punchOutTime != null) {
    punchStatus = "done";
    statusText = "Completed";
    isRunning = false;
  } 
  else {
    punchStatus = "in";
    statusText = "Punch In";
    isRunning = false;
  }
}
  else {
  todayStatus = "";
  punchStatus = "in";
  statusText = "Punch In";
}

  notifyListeners();
} 
String get todayFormatted =>
      DateFormat("EEEE, MMMM d yyyy").format(DateTime.now());

  Duration get totalWorkedDuration {
    if (punchInTime == null || punchOutTime == null) {
      return Duration.zero;
    }
    return punchOutTime!.difference(punchInTime!);
  }

  String get formattedTotalHours {
    final duration = totalWorkedDuration;
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return "${h}h ${m}m";
  }

 int get presentDays {
  final list = filteredAttendance.isEmpty
      ? attendanceList
      : filteredAttendance;

  return list.where((e) {
    final status = (e['status'] ?? '').toString().toLowerCase();
    return status == 'present' || status == 'approved';
  }).length;
}

  int get absentDays {
  final all = filteredAttendance.isEmpty
      ? attendanceList
      : filteredAttendance;

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final Set<String> activeUsers = {};

  for (var e in all) {
    if (e['date'] != today) continue;

    final status = (e['status'] ?? '').toString().toLowerCase();

    if (status == 'approved' ||
        status == 'pending' ||
        status == 'leave') {
      activeUsers.add(e['user_id']);
    }
  }

  final totalUsers = employeeList
      .where((e) => e['role'] != 'superadmin')
      .map((e) => e['id'])
      .toSet();

  return totalUsers.difference(activeUsers).length;
}
  int get pendingDays {
    final list = filteredAttendance.isEmpty
        ? attendanceList
        : filteredAttendance;
    return list.where((e) => e['status'] == "pending").length;
  }

  int get leaveDays {
    final list = filteredAttendance.isNotEmpty
        ? filteredAttendance
        : attendanceList;

    return list
        .where((e) => (e['status'] ?? '').toLowerCase() == "leave")
        .length;
  }

  int get rejectedDays {
    final list = filteredAttendance.isEmpty
        ? attendanceList
        : filteredAttendance;
    return list.where((e) => e['status'] == "rejected").length;
  }

  // present or absent
  bool get isPresentToday {
    if (punchInTime == null) return false;

    final now = DateTime.now();

    return punchInTime!.year == now.year &&
        punchInTime!.month == now.month &&
        punchInTime!.day == now.day;
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMonthlyLeaveCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final response = await supabase
        .from('leave_requests')
        .select('start_date, end_date')
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .gte('start_date', startOfMonth)
        .lte('end_date', endOfMonth);
    print("user start_date : ${startOfMonth}");
    print("user end_date : ${endOfMonth}");

    int totalDays = 0;

    for (var leave in response) {
      DateTime start = DateTime.parse(leave['start_date']);
      DateTime end = DateTime.parse(leave['end_date']);
      totalDays += end.difference(start).inDays + 1;
      print("user start_date 1 : ${start}");
      print("user end_date 1 : ${end}");
      print("user totalDays  : ${totalDays}");
    }
    print("user totalDays 1  : ${totalDays}");

    monthlyLeaveDays = totalDays;
    print("user monthlyLeaveDays  : ${monthlyLeaveDays}");
    notifyListeners();
  }

 bool _isLoadingAttendance = false; // 🔥 prevent multiple calls

Future<void> loadAttendance([String? userId]) async {
  if (_isLoadingAttendance) return;
  _isLoadingAttendance = true;

  final user = supabase.auth.currentUser;
  if (user == null) {
    _isLoadingAttendance = false;
    return;
  }

  final targetUserId = userId ?? user.id;

  try {
    final now = DateTime.now();

DateTime cycleStart;
DateTime cycleEnd;

if (now.day >= 25) {
  cycleStart = DateTime(now.year, now.month, 25);
  cycleEnd = DateTime(now.year, now.month + 1, 24);
} else {
  cycleStart = DateTime(now.year, now.month - 1, 25);
  cycleEnd = DateTime(now.year, now.month, 24);
}

final response = await supabase
    .from('attendance')
    .select('user_id, date, status, punch_in, punch_out, punch_in_location, punch_out_location, earned_amount')
    .eq('user_id', targetUserId)
    .gte('date', DateFormat('yyyy-MM-dd').format(cycleStart))
    .lte('date', DateFormat('yyyy-MM-dd').format(cycleEnd))
    .order('date', ascending: false);

    attendanceList = List<Map<String, dynamic>>.from(response);
    
    await loadTodayPunch();
    notifyListeners();
  } catch (e) {
    print("ERROR: $e");
  } finally {
    _isLoadingAttendance = false;
  }
}
bool isImageUploading = false;

  Future<void> uploadProfileImage(File imageFile, BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      isImageUploading = true;
      notifyListeners();

      final fileName = "${user.id}.jpg";

      await supabase.storage
          .from('profile-images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'profile_image_url': imageUrl})
          .eq('id', user.id);

      profileImageUrl = imageUrl;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image uploaded successfully ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed ❌ $e")));
    } finally {
      isImageUploading = false;
      notifyListeners();
    }
  }

  void resetData() {}
  // =====================
// HOLIDAY FUNCTIONS
// =====================

Future<void> loadHolidays() async {
  final res = await supabase
      .from('holidays')
      .select('holiday_date, name');

  holidays = [];
  holidayReasons = {};

  for (final item in res) {
    final rawDate = item['holiday_date'];

    DateTime date = DateTime.parse(rawDate.toString());

    /// REMOVE TIME
    date = DateTime(date.year, date.month, date.day);

    final key =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    holidays.add(date);
    holidayReasons[key] = item['name'] ?? "Holiday";
  }

  print("HOLIDAYS: $holidayReasons");

  notifyListeners();
}
bool isHoliday(DateTime date) {
  final key =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  return holidayReasons.containsKey(key);
}

String getHolidayReason(DateTime date) {
  final key =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  return holidayReasons[key] ?? "Holiday";
}
  //leave approvel container
  Future<List<Map<String, dynamic>>> fetchMyLeaves() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('leave_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  //super admin
  int totalEmployees = 0;
  int totalPresentEmployees = 0;
  int totalAbsentEmployees = 0;
  int totalPendingEmployees = 0;
  int totalLeaveEmployees = 0;
 Future<void> loadSuperAdminStats() async {
  try {
   
    await loadAllAttendance();         
    await loadTodayAllAttendance(); 
    final now = DateTime.now();

    final startOfMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    /// 1️⃣ GET USERS (exclude superadmin)
    final users = await supabase
        .from('users')
        .select('id')
        .neq('role', 'superadmin');

    totalEmployees = users.length;

    final Set<String> allUserIds =
        users.map((e) => e['id'].toString()).toSet();

    /// 2️⃣ TODAY ATTENDANCE
    final approvedToday = await supabase
        .from('attendance')
        .select('user_id')
        .eq('date', today)
        .or('status.eq.approved,status.eq.present');

    final pendingToday = await supabase
        .from('attendance')
        .select('user_id')
        .eq('date', today)
        .eq('status', 'pending');

    final leaveToday = await supabase
        .from('leave_requests')
        .select('user_id')
        .eq('status', 'approved')
        .lte('start_date', today)
        .gte('end_date', today);

    totalPresentEmployees =
        approvedToday.map((e) => e['user_id']).toSet().length;

    totalPendingEmployees =
        pendingToday.map((e) => e['user_id']).toSet().length;

    final Set<String> leaveTodayIds =
        leaveToday.map((e) => e['user_id'].toString()).toSet();

    totalLeaveEmployees = leaveTodayIds.length;

    /// 3️⃣ MONTH ATTENDANCE
    final monthAttendance = await supabase
        .from('attendance')
        .select('user_id,status')
        .gte('date', startOfMonth)
        .lte('date', today);

    final Set<String> presentIds = {};
    final Set<String> pendingIds = {};

    for (var row in monthAttendance) {
      final status = row['status'];
      final userId = row['user_id'].toString();

      if (status == 'approved') {
        presentIds.add(userId);
      } else if (status == 'pending') {
        pendingIds.add(userId);
      }
    }

    /// 4️⃣ MONTH LEAVE
    final leaveMonth = await supabase
        .from('leave_requests')
        .select('user_id')
        .eq('status', 'approved')
        .lte('start_date', today)
        .gte('start_date', startOfMonth);

    final Set<String> leaveMonthIds =
        leaveMonth.map((e) => e['user_id'].toString()).toSet();
/// ✅ TODAY ACTIVE USERS ONLY
final Set<String> todayPresentIds =
    approvedToday.map((e) => e['user_id'].toString()).toSet();

final Set<String> todayPendingIds =
    pendingToday.map((e) => e['user_id'].toString()).toSet();

final Set<String> todayLeaveIds =
    leaveToday.map((e) => e['user_id'].toString()).toSet();

/// ✅ HOLIDAY CHECK
final bool todayIsHoliday = isHoliday(DateTime.now());

Set<String> absentIds = {};

final cutoff = DateTime(
  now.year,
  now.month,
  now.day,
  11,
  0,
);

if (!todayIsHoliday && now.isAfter(cutoff)) {
  final Set<String> todayActive = {
    ...todayPresentIds,
    ...todayPendingIds,
    ...todayLeaveIds,
  };

  absentIds = allUserIds.difference(todayActive);
} else {
  absentIds = {};
}

    /// 6️⃣ FINAL ASSIGNMENTS
   
totalPresentEmployees = todayPresentIds.length;

/// direct month pending count
final monthPending = await supabase
    .from('attendance')
    .select('id')
    .eq('status', 'pending')
    .gte('date', startOfMonth)
    .lte('date', today);

totalPendingEmployees = monthPending.length;

totalLeaveEmployees = todayLeaveIds.length;
totalAbsentEmployees = absentIds.length;
    /// DEBUG LOGS
    print("Total Employees: $totalEmployees");
    print("Present: $totalPresentEmployees");
    print("Pending: $totalPendingEmployees");
    print("Leave: $totalLeaveEmployees");
    print("Absent: $totalAbsentEmployees");

    notifyListeners();
  } catch (e) {
    print("SuperAdmin Stats Error: $e");
  }
}
  //total employees list
  //  exclude superadmin
          

    Future<void> loadEmployees() async {
  try {
    final users = await supabase
        .from('users')
        .select()
        .neq('role', 'superadmin');

    final attendance = await supabase
        .from('attendance')
        .select('user_id, earned_amount, status');

    for (var user in users) {
      double totalNetSalary = 0;

      for (var row in attendance) {
        if (row['user_id'] == user['id'] &&
            row['status'] == 'pending') {
          totalNetSalary +=
              double.tryParse(row['earned_amount'].toString()) ?? 0;
        }
      }

      user['net_salary'] = totalNetSalary;
    }

    employeeList = List<Map<String, dynamic>>.from(users);

    notifyListeners();
  } catch (e) {
    print("Employee Load Error: $e");
  }
}

 List<Map<String, dynamic>> get todayPresentEmployeesList {
final presentIds = todayAttendance
    .where((e) =>
        e['status'] == 'approved' ||
        e['status'] == 'pending')
    .map((e) => e['user_id'])
    .toSet();

  return employeeList
      .where(
        (user) =>
            user['role'] != 'superadmin' &&
            presentIds.contains(user['id']),
      )
      .toList();
}

  //total pending employees
List<Map<String, dynamic>> get todayPendingEmployeesList {
  return todayAttendance
      .where(
        (e) =>
            (e['status'] ?? '')
                .toString()
                .toLowerCase() ==
            'pending',
      )
      .toList();
}
  //total absent employees
  List<Map<String, dynamic>> get todayAbsentEmployeesList {
   
     print("EMPLOYEES: ${employeeList.map((e) => e['id']).toList()}");

  print("TODAY ATTENDANCE FULL:");
  for (var e in todayAttendance) {
    print("USER: ${e['user_id']} STATUS: ${e['status']}");
  }

  print("LEAVE IDS: ${leaveList.map((e) => e['user_id']).toList()}");
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// ✅ Get all users
  final allIds = employeeList
      .where((e) => e['role'] != 'superadmin')
      .map((e) => e['id'])
      .toSet();

  /// ✅ Present (approved only)
 final presentIds = todayAttendance
    .where((e) => e['status'] == 'approved')
    .map((e) => e['user_id'])
    .toSet();

final pendingIds = todayAttendance
    .where((e) => e['status'] == 'pending')
    .map((e) => e['user_id'])
    .toSet();
  /// ✅ Leave
 final leaveIds = leaveList
    .map((e) => e['user_id'].toString())
    .toSet();
  /// ✅ Active users (NOT absent)
  final activeIds = {
    ...presentIds,
    ...pendingIds,
    ...leaveIds,
  };

 /// ✅ Holiday = no absent employees
if (isHoliday(DateTime.now())) {
  print("TODAY IS HOLIDAY — NO ABSENT");
  return [];
}
final now = DateTime.now();

final cutoff = DateTime(
  now.year,
  now.month,
  now.day,
  11,
  0,
);

if (now.isBefore(cutoff)) {
  return [];
}

/// ✅ Absent calculation
final absentIds = allIds.difference(activeIds);
  print("ALL IDS: $allIds");
  print("ACTIVE IDS: $activeIds");
  print("ABSENT IDS: $absentIds");

  return employeeList.where((emp) {
    return absentIds.contains(emp['id']);
  }).toList();
}

  //total leave employees
  List<Map<String, dynamic>> get todayLeaveEmployeesList {
    final leaveIds = leaveList
        .map<String>((e) => e['user_id'] as String)
        .toList();

    return employeeList.where((user) => leaveIds.contains(user['id'])).toList();
  }

  Future<void> loadTodayLeave() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final response = await supabase
        .from('leave_requests')
        .select()
        .lte('start_date', today)
        .gte('end_date', today)
        .eq('status', 'approved');


    leaveList = List<Map<String, dynamic>>.from(response);

    print("Leave List: $leaveList");
    print("Employee IDs: ${employeeList.map((e) => e['id']).toList()}");

    notifyListeners();
  }

  void filterAttendanceByDate(DateTime start, DateTime end) {
    selectedStartDate = start;
    selectedEndDate = end;

    filteredAttendance = attendanceList.where((item) {
      if (item['date'] == null) return false;

      DateTime date = DateTime.parse(item['date']).toLocal();

      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    notifyListeners();
  }

  Future<void> loadStatsByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final now = DateTime.now();

    /// 1️⃣ Load employees with join date
    final users = await supabase.from('users').select('id, joining_date, role');

    final validUsers = users.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role != 'superadmin';
    }).toList();
    final Map<String, DateTime> joinDates = {
      for (var u in users) u['id']: DateTime.parse(u['joining_date']),
    };

    /// total employees in that month
    totalEmployees = users.where((u) {
      final jd = DateTime.parse(u['joining_date']);
      return jd.isBefore(end) || jd.isAtSameMomentAs(end);
    }).length;

    /// 2️⃣ Attendance
    final attendance = await supabase
        .from('attendance')
        .select()
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0]);

    totalPendingEmployees = 0;
    totalAbsentEmployees = 0;
    totalLeaveEmployees = 0;

    for (final item in attendance) {
      final status = item['status'];
      final date = DateTime.parse(item['date']);
      final validUserIds = validUsers.map((u) => u['id']).toSet();
      final userId = item['user_id'];

      if (!validUserIds.contains(userId)) continue; // 🚀 FILTER HERE
      final joinDate = joinDates[userId];
      if (joinDate != null && date.isBefore(joinDate)) continue;

      if (month.month == now.month && date.isAfter(now)) continue;

      if (status == 'pending') {
        totalPendingEmployees++;
      } else if (status == 'absent') {
        totalAbsentEmployees++;
      }
    }

    /// 3️⃣ Leave
    final leaves = await supabase
        .from('leave_requests')
        .select()
        .eq('status', 'approved');

    for (final leave in leaves) {
      final startLeave = DateTime.parse(leave['start_date']);
      final endLeave = DateTime.parse(leave['end_date']);
      final userId = leave['user_id'];

      final joinDate = joinDates[userId];

      for (
        DateTime d = startLeave;
        !d.isAfter(endLeave);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month != month.month) continue;
        if (month.month == now.month && d.isAfter(now)) continue;

        if (joinDate != null && d.isBefore(joinDate)) continue;

        totalLeaveEmployees++;
      }
    }

    notifyListeners();
  }

  Future<void> loadStatsByRange(DateTime start, DateTime end) async {
    final requestId = ++_statsRequestId;

    _isLoadingStats = true;

    currentStartDate = start;
    currentEndDate = end;

    final startDate = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateFormat('yyyy-MM-dd').format(end);

    try {
      /// TOTAL EMPLOYEES
      final users = await supabase
          .from('users')
          .select('id')
          .neq('role', 'superadmin');

      totalEmployees = users.length;

      /// ATTENDANCE
      final attendance = await supabase
          .from('attendance')
          .select('user_id,status')
          .gte('date', startDate)
          .lte('date', endDate);

      final Set<String> presentIds = {};
      final Set<String> pendingIds = {};
      final Set<String> allAttendanceIds = {};

      for (var row in attendance) {
        final id = row['user_id'];
        final status = row['status'];

        allAttendanceIds.add(id);

        if (status == 'approved') {
          presentIds.add(id);
        }

        if (status == 'pending') {
          pendingIds.add(id);
        }
      }

      /// LEAVE
      final leave = await supabase
          .from('leave_requests')
          .select('user_id')
          .eq('status', 'approved')
          .lte('start_date', endDate)
          .gte('end_date', startDate);

      final leaveIds = leave.map((e) => e['user_id']).toSet();

      /// ABSENT
      final attendedOrLeave = {...presentIds, ...pendingIds, ...leaveIds};

      int absent = totalEmployees - attendedOrLeave.length;

      if (absent < 0) absent = 0;

      print("Total Employees: $totalEmployees");
      print("Present IDs: $presentIds");
      print("Pending IDs: $pendingIds");
      print("Leave IDs: $leaveIds");
      print("AttendedOrLeave: $attendedOrLeave");
      print("Absent Count: $absent");

      /// UPDATE STATE
      totalPresentEmployees = presentIds.length;
      totalPendingEmployees = pendingIds.length;
      totalLeaveEmployees = leaveIds.length;
      totalAbsentEmployees = absent;
    } catch (e) {
      debugPrint("Stats error: $e");
    }

    _isLoadingStats = false;

    notifyListeners();
  }

 Map<String, int> getSummary() {
  int present = 0;
  int absent = 0;
  int leave = 0;
  int pending = 0;

  for (final a in attendanceList) {
    final status = a['status'];

    switch (status) {
      case 'present':
        case 'approved':
  present++;
  break;
      case 'absent':
        absent++;
        break;
      case 'leave':
        leave++;
        break;
      case 'pending':
        pending++;
        break;
        
    }
  }

  return {
    'present': present,
    'absent': absent,
    'leave': leave,
    'pending': pending,
  };
}

 List<Map<String, dynamic>> getMonthAbsentEmployees(DateTime selectedMonth) {
  List<Map<String, dynamic>> result = [];

  final now = DateTime.now();

  final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  for (final user in employeeList) {
    if (user['role'] == 'superadmin') continue;

    final schedule = user['work_schedule'] ?? "mon_sat";
    final joiningDate = DateTime.parse(user['joining_date']);

    final start = joiningDate.isAfter(monthStart) ? joiningDate : monthStart;

    for (DateTime d = start;
        !d.isAfter(monthEnd);
        d = d.add(const Duration(days: 1))) {

      /// 🚫 Skip future dates
      if (selectedMonth.year == now.year &&
          selectedMonth.month == now.month &&
          d.isAfter(now)) continue;

      /// 🚫 Weekly off
      if (schedule == "mon_fri") {
        if (d.weekday == DateTime.saturday ||
            d.weekday == DateTime.sunday) continue;
      } else {
        if (d.weekday == DateTime.sunday) continue;
      }

      /// 🚫 Holiday
      if (isHoliday(d)) continue;

      final dateKey =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      /// ✅ Attendance record
      final record = attendanceList.firstWhere(
        (a) =>
            a['user_id'].toString() == user['id'].toString() &&
            a['date'].toString().substring(0, 10) == dateKey,
        orElse: () => {},
      );

     bool hasValidPunch = false;

if (record.isNotEmpty) {
  final hasPunchIn = record['punch_in'] != null;
  final status = (record['status'] ?? '').toString().toLowerCase();

  /// 🔥 FINAL CORRECT LOGIC
  if (hasPunchIn && status != 'rejected') {
    hasValidPunch = true;
  }
}

      /// ✅ Leave check
      final isOnLeave = leaveList.any((leave) {
        final startLeave = DateTime.parse(leave['start_date']);
        final endLeave = DateTime.parse(leave['end_date']);

        return leave['user_id'] == user['id'] &&
            !d.isBefore(startLeave) &&
            !d.isAfter(endLeave);
      });

      /// ❌ Final absent rule
  
final todayKey = DateFormat('yyyy-MM-dd').format(now);

bool isToday = dateKey == todayKey;


if (isToday) {
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
    11,
    0,
  );

  if (now.isBefore(cutoff)) {
    continue;
  }
}

if (!hasValidPunch && !isOnLeave) {
  result.add({
    "name": user['name'],
    "department": user['department'],
    "profile_image_url": user['profile_image_url'],
    "date": dateKey,
    "status": "absent",
  });
}
    }
  }

  print("FINAL ABSENT LIST => ${result.length}");
  return result;
}
 
  Future<void> fetchLeaveList() async {
    final data = await supabase
        .from('leave_requests')
        .select('*, users!leave_requests_user_id_fkey(name, department)')
        .eq('status', 'approved');

    print("LEAVE TABLE DATA: $data");

    leaveList = List<Map<String, dynamic>>.from(data);

    notifyListeners();
  }

  List<Map<String, dynamic>> get currentMonthLeaveEmployeesList {
    final now = DateTime.now();
    List<Map<String, dynamic>> expandedList = [];

    for (final leave in leaveList) {
      final startDate = DateTime.parse(leave['start_date']);
      final endDate = DateTime.parse(leave['end_date']);

      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.month != now.month || d.year != now.year) continue;

        final item = Map<String, dynamic>.from(leave);

        /// override date so UI shows each day
        item['start_date'] = d.toIso8601String();

        expandedList.add(item);
      }
    }

    return expandedList;
  }
  

 Future<void> loadAllAttendance() async {

  /// LOAD ALL ATTENDANCE
  final allResponse = await supabase
      .from('attendance')
      .select('user_id, date, status, punch_in, earned_amount');

  attendanceList = List<Map<String, dynamic>>.from(allResponse);

  /// LOAD ONLY TODAY ATTENDANCE
  final today =
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  final todayResponse = await supabase
      .from('attendance')
      .select('user_id, date, status, punch_in')
      .eq('date', today);

  todayAttendance =
      List<Map<String, dynamic>>.from(todayResponse);

  print("ALL DATA: ${attendanceList.length}");
  print("TODAY DATA: ${todayAttendance.length}");

  notifyListeners();
}
int selectedMonth = DateTime.now().month;

  void setSelectedMonth(int month) {
    selectedMonth = month;
    notifyListeners();
  }
 


}
