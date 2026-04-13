import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class PunchProvider extends ChangeNotifier {
  PunchProvider() {}
  List<Map<String, dynamic>> attendanceList = [];
  List<Map<String, dynamic>> employeeList = [];
  List<Map<String, dynamic>> todayAttendance = [];
  List<String> todayLeaveUserIds = [];
  List<Map<String, dynamic>> leaveList = [];
  List<Map<String, dynamic>> filteredAttendance = [];
  

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
  String locationAddress = "--";
  String photoUrl = '';

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

  int totalLeaveDays = 0;
  int leaveBalance = 0;
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
    await loadProfile();

   await loadHolidays(); // ✅ MUST BE FIRST

await loadAllAttendance();
await loadTodayPunch();
await loadMonthlyLeaveCount();
await loadEmployees();
await loadTodayLeave();
    if (role == 'superadmin' || role == 'admin' || role == 'hr') {
      await loadSuperAdminStats(); //  USE DAILY STATS
    }
    listenAttendanceChanges();

    isLoaded = true;
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

  //  PUNCH IN
  Future<void> punchIn(String location, BuildContext context) async {
    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      return;
    }

    /// SHOW LOADER FIRST
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const Center(child: CircularProgressIndicator()),
    // );

    try {
      final now = DateTime.now();
      final dateOnly = DateFormat('yyyy-MM-dd').format(now);


if (isHoliday(now)) {
  punchInTime = null;
  punchOutTime = null;
  isRunning = false;
  punchStatus = "holiday";
  statusText = "🎉 Holiday";

  todayStatus = "holiday";

  notifyListeners();
  return;
}
      /// CHECK EXISTING PUNCH
      final existing = await supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id)
          .eq('date', dateOnly)
          .maybeSingle();

      if (existing != null) {
        if (context.mounted) Navigator.pop(context); // stop loader

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Already punched today")));
        return;
      }

      /// INSERT DATA
      await supabase.from('attendance').insert({
        'user_id': user.id,
        'date': dateOnly,
        'punch_in': now.toIso8601String(),
        'location': location,
      });

      /// UPDATE STATE
      punchInTime = now;
      punchOutTime = null;
      isRunning = true;
      punchStatus = "out";
      statusText = "Punched In";
      locationAddress = location;

      await loadAttendance();
      notifyListeners();

      // /// CLOSE LOADER
      // if (context.mounted) Navigator.pop(context);

      /// SUCCESS POPUP
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Punch In Successful"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📅 Date: ${DateFormat('dd MMM yyyy').format(now)}"),
              const SizedBox(height: 5),
              Text("🕧 Time: ${DateFormat('hh:mm a').format(now)}"),
              const SizedBox(height: 5),
              Text("📍 Location: $location"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // stop loader

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // PUNCH OUT
  Future<void> punchOut(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null || punchInTime == null) return;

    final picker = ImagePicker();

    /// OPEN CAMERA
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    /// If user cancels camera
    if (photo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Punch out cancelled")));
      return;
    }

    final now = DateTime.now();
    final dateOnly = DateFormat('yyyy-MM-dd').format(now);

    try {
      /// UPDATE DB (NO IMAGE STORED)
      await supabase
          .from('attendance')
          .update({'punch_out': now.toIso8601String()})
          .eq('user_id', user.id)
          .eq('date', dateOnly);

      /// UPDATE LOCAL STATE
      punchOutTime = now;
      isRunning = false;
      punchStatus = "done";
      statusText = "Punched Out";

      notifyListeners();

      /// SUCCESS MESSAGE
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text("Punch Out Successful")));
    } catch (e) {
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text("Punch out failed: $e")));
    }
  }

 Future<void> loadTodayPunch() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);

  punchInTime = null;
  punchOutTime = null;
  isRunning = false;
  punchStatus = "in";
  statusText = "Punch In";
  todayStatus = "";
  locationAddress = "--";

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
      .select('punch_in, punch_out, location, status')
      .eq('user_id', user.id)
      .eq('date', today)
      .maybeSingle();

  if (data != null) {
    todayStatus = data['status'];

    if (data['punch_in'] != null) {
      punchInTime = DateTime.parse(data['punch_in']);
    }

    if (data['punch_out'] != null) {
      punchOutTime = DateTime.parse(data['punch_out']);
    }

    locationAddress = data['location'] ?? "--";

    if (todayStatus == 'rejected') {
      punchStatus = "absent";
      statusText = "Absent";

    } else if (punchOutTime != null) {
      punchStatus = "done";
      statusText = "Punched Out";

    } else if (todayStatus == 'approved') {
      punchStatus = "approved";
      statusText = "Present";

    } else if (punchInTime != null) {
      punchStatus = "out";
      statusText = "Pending";

    } else {
      punchStatus = "in";
      statusText = "Punch In";
    }

  } else {
  final cutoff = DateTime(now.year, now.month, now.day, 10, 30);

  if (now.isAfter(cutoff)) {
    /// 🔴 MARK ABSENT
    todayStatus = "absent";
    punchStatus = "absent";
    statusText = "Absent";

    /// 🔥 OPTIONAL: insert absent record (VERY IMPORTANT for summary)
    await supabase.from('attendance').upsert({
      'user_id': user.id,
      'date': today,
      'status': 'absent',
    });
  } else {
    todayStatus = "";
    punchStatus = "in";
    statusText = "Punch In";
  }
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
    return list.where((e) => e['status'] == "approved").length;
  }

  int get absentDays {
    final now = DateTime.now();
    final schedule = workSchedule ?? "mon_fri";

    int holidayCount = 0;

    for (int i = 1; i <= now.day; i++) {
      DateTime date = DateTime(now.year, now.month, i);

      if (schedule == "mon_fri") {
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          holidayCount++;
        }
      } else {
        if (date.weekday == DateTime.sunday) {
          holidayCount++;
        }
      }
    }

    int workingDays = now.day - holidayCount;

    int recordedDays = presentDays + pendingDays + rejectedDays + leaveDays;

    int autoAbsent = workingDays - recordedDays;

    if (autoAbsent < 0) autoAbsent = 0;

    /// 11 AM RULE
    final cutoffTime = DateTime(now.year, now.month, now.day, 11, 0);

    bool isOnLeaveToday = todayStatus == 'leave';
    bool hasPunchedToday = punchInTime != null;

    if (now.isAfter(cutoffTime) && !hasPunchedToday && !isOnLeaveToday) {
      autoAbsent += 1;
    }

    return autoAbsent;
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
  if (_isLoadingAttendance) return; // 🛑 STOP duplicate calls
  _isLoadingAttendance = true;

  final user = supabase.auth.currentUser;
  if (user == null) {
    _isLoadingAttendance = false;
    return;
  }

  final targetUserId = userId ?? user.id;

  try {
    /// 🔥 FETCH ONLY CURRENT USER
    final response = await supabase
        .from('attendance')
        .select('user_id, date, status, punch_in, punch_out')
        .eq('user_id', targetUserId)
        .order('date', ascending: false);

    print("RAW DATA LENGTH: ${response.length}");

    /// 🔥 FORCE UNIQUE BY DATE
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (var item in response) {
      final date = item['date'];

      /// 🛑 only keep first occurrence
      if (!uniqueMap.containsKey(date)) {
        uniqueMap[date] = item;
      }
    }

    final cleanList = uniqueMap.values.toList();

    print("CLEAN DATA LENGTH: ${cleanList.length}");

    attendanceList = List<Map<String, dynamic>>.from(cleanList);
    todayAttendance = List<Map<String, dynamic>>.from(cleanList);

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
        .eq('status', 'approved');

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

    /// 5️⃣ FINAL ABSENT LOGIC (IMPORTANT FIX)
    final Set<String> activeUsers =
        presentIds.union(leaveMonthIds);

    final Set<String> absentIds =
        allUserIds.difference(activeUsers);

    /// 6️⃣ FINAL ASSIGNMENTS
    totalPresentEmployees = presentIds.length;
    totalPendingEmployees = pendingIds.length;
    totalLeaveEmployees = leaveMonthIds.length;
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
  Future<void> loadEmployees() async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .neq('role', 'superadmin'); //  exclude superadmin

      employeeList = List<Map<String, dynamic>>.from(data);

      totalEmployees = employeeList.length;

      notifyListeners();
    } catch (e) {
      print("Employee Load Error: $e");
    }
  }

  // total present employees
  List<Map<String, dynamic>> get todayPresentEmployeesList {
    final presentIds = attendanceList
        .where((e) => e['status'] == 'approved')
        .map<String>((e) => e['user_id'] as String)
        .toList();

    return employeeList
        .where(
          (user) =>
              user['role'] != 'superadmin' && presentIds.contains(user['id']),
        )
        .toList();
  }

  //total pending employees
  List<Map<String, dynamic>> get todayPendingEmployeesList {
    final today = DateTime.now();

    final todayString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    /// get pending user ids
    final pendingIds = attendanceList
        .where(
          (e) =>
              e['date'] == todayString &&
              (e['status'] ?? '').toLowerCase() == 'pending',
        )
        .map((e) => e['user_id'])
        .toList();

    /// match employees with those ids
    return employeeList.where((emp) => pendingIds.contains(emp['id'])).toList();
  }

  //total absent employees
  List<Map<String, dynamic>> get todayAbsentEmployeesList {
    final attendedIds = todayAttendance.map((e) => e['user_id']).toSet();

    return employeeList.where((emp) {
      if (emp['role'] == 'superadmin') return false;

      return !attendedIds.contains(emp['id']);
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
    final list = filteredAttendance.isNotEmpty
        ? filteredAttendance
        : attendanceList;

    int present = 0;
    int pending = 0;
    int leave = 0;
    int absent = 0;

    for (var item in list) {
      final status = item['status'];

      if (status == 'approved') {
        present++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'leave') {
        leave++;
      }
    }

    return {
      "present": present,
      "pending": pending,
      "leave": leave,
      "absent": absent,
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

    for (
      DateTime d = start;
      !d.isAfter(monthEnd);
      d = d.add(const Duration(days: 1))
    ) {
      /// 🚫 Skip future dates (only current month)
      if (selectedMonth.year == now.year &&
          selectedMonth.month == now.month &&
          d.isAfter(now)) continue;

      /// 🚫 Skip weekly off
      if (schedule == "mon_fri") {
        if (d.weekday == DateTime.saturday ||
            d.weekday == DateTime.sunday) continue;
      } else {
        if (d.weekday == DateTime.sunday) continue;
      }

      /// 🚫 Skip HOLIDAY (🔥 IMPORTANT FIX)
      if (isHoliday(d)) continue;

      final dateKey =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      /// ✅ Check attendance
      final record = attendanceList.where((a) =>
          a['user_id'] == user['id'] &&
          a['date'] == dateKey);

      DateTime cutoffTime = DateTime(d.year, d.month, d.day, 10, 30);

      bool hasValidPunch = false;

      if (record.isNotEmpty) {
        final r = record.first;

        if (r['punch_in'] != null) {
          DateTime punchIn = DateTime.parse(r['punch_in']);

          /// ✅ BEFORE 10:30 → Present
          if (punchIn.isBefore(cutoffTime)) {
            hasValidPunch = true;
          }
        }

        /// Approved also counts
        if (r['status'] == 'approved') {
          hasValidPunch = true;
        }
      }

      /// ✅ Check leave
      final isOnLeave = leaveList.any((leave) {
        final startLeave = DateTime.parse(leave['start_date']);
        final endLeave = DateTime.parse(leave['end_date']);

        return leave['user_id'] == user['id'] &&
            !d.isBefore(startLeave) &&
            !d.isAfter(endLeave);
      });

      /// ❌ FINAL ABSENT RULE
      if (!hasValidPunch && !isOnLeave) {
        /// 🕒 Only after 10:30 for today
        if (d.year == now.year &&
            d.month == now.month &&
            d.day == now.day) {
          if (now.isBefore(cutoffTime)) continue;
        }

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
    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T')[0];

    final today = now.toIso8601String().split('T')[0];

    final response = await supabase
        .from('attendance')
         .select('user_id, date, status, punch_in');
    // .gte('date', startOfMonth)
    // .lte('date', today);

    attendanceList = List<Map<String, dynamic>>.from(response);
    print("ALL DATA: $attendanceList");
    notifyListeners();
  }

  int selectedMonth = DateTime.now().month;

  void setSelectedMonth(int month) {
    selectedMonth = month;
    notifyListeners();
  }
  

 

 
}
