import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeedz_attendance/widget/recentdetails.dart';
import 'package:zeedz_attendance/widget/salary_chart.dart';
import 'package:zeedz_attendance/widget/salaryskeleton.dart';
import 'package:zeedz_attendance/widget/sectioncard.dart';
import 'package:zeedz_attendance/widget/smallcard.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class EmployeeSalaryPage extends StatefulWidget {
  final String? employeeId;

  const EmployeeSalaryPage({super.key, this.employeeId,});

  @override
  State<EmployeeSalaryPage> createState() => _EmployeeSalaryPageState();
}

class _EmployeeSalaryPageState extends State<EmployeeSalaryPage> {
     DateTime? joiningDate;
  final supabase = Supabase.instance.client;
  String get selectedUserId {
  return widget.employeeId ??
      supabase.auth.currentUser!.id;
}
 List<Map<String, double>> monthlyData = [];
List<int> chartMonths = [];
 double monthlyTargetHours = 0;
 double remainingHours = 0;
 double totalWorkedHours = 0;
 double earnedToday = 0;
double todayNet = 0;
double totalNet = 0;
double todayDeduction = 0;
double totalDeductionAll = 0;
double cycleDeductionLive = 0;
  double net = 0;
  double grossSalary = 0;
  double totalDeduction = 0;
 double totalSalary = 0;
  String gross = "₹0";
  String deduction = "₹0";
  String employeeRole = '';
  double leaveDeduction = 0;
bool absentChecked = false;
  List<Map<String, dynamic>> recentList = [];

  bool animateSalary = false;
  bool isLoading = true;
  bool isRefreshing = false;

  Timer? timer;
   // 👇 PASTE HERE
  double getSalaryByRole(String role) {
    switch (role) {
      case 'intern':
        return 3000;
      case 'hr':
        return 5000;
      case 'admin':
        return 8000;
      case 'super_admin':
        return 10000;
      default:
        return 4000;
    }
  }

 DateTime getCycleStart(DateTime joiningDate, DateTime now) {
  DateTime start = joiningDate;

  while (true) {
    final next = DateTime(
      start.year,
      start.month + 1,
      start.day,
    );

    if (now.isBefore(next)) break;

    start = next;
  }

  return start;
}
DateTime getCycleEnd(DateTime cycleStart) {
  return DateTime(
    cycleStart.year,
    cycleStart.month + 1,
    cycleStart.day,
  ).subtract(const Duration(days: 1));
}
  String getTodayDate(DateTime now) {
    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  /// ✅ IGNORE TIMEZONE COMPLETELY
  DateTime parsePunchIn(dynamic value) {
    final raw = value.toString();
    final dt = DateTime.parse(raw);

    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }
  
  Future<DateTime> getJoiningDate() async {
  final response = await supabase
      .from('users')
      .select('joining_date, role')
      .eq('id', selectedUserId)
      .single();

  employeeRole = response['role'] ?? '';

  return DateTime.parse(response['joining_date']);
}
  Future<double> loadCurrentCycleEarnedFromDB() async {
  final userId = selectedUserId;
  final now = DateTime.now();

  if (joiningDate == null) return 0;

  final cycleStart = getCycleStart(joiningDate!, now);
 final cycleEnd = getCycleEnd(cycleStart);

  final response = await supabase
      .from('attendance')
      .select('earned_amount,date,status')
      .eq('user_id', userId)
      .gte(
        'date',
        "${cycleStart.year.toString().padLeft(4, '0')}-"
        "${cycleStart.month.toString().padLeft(2, '0')}-"
        "${cycleStart.day.toString().padLeft(2, '0')}",
      )
      .lte(
        'date',
        "${cycleEnd.year.toString().padLeft(4, '0')}-"
        "${cycleEnd.month.toString().padLeft(2, '0')}-"
        "${cycleEnd.day.toString().padLeft(2, '0')}",
      );

  double total = 0;

  for (var row in response) {
    total += double.tryParse(row['earned_amount'].toString()) ?? 0;
  }

  return total;
}
Future<double> loadCurrentCycleDeductionFromDB() async {
 final userId = selectedUserId;

  final now = DateTime.now();

  if (joiningDate == null) return 0;

  final cycleStart = getCycleStart(joiningDate!, now);
 final cycleEnd = getCycleEnd(cycleStart);

  final response = await supabase
      .from('attendance')
      .select('deductions')
      .eq('user_id', userId)
      .gte(
        'date',
        "${cycleStart.year.toString().padLeft(4, '0')}-"
        "${cycleStart.month.toString().padLeft(2, '0')}-"
        "${cycleStart.day.toString().padLeft(2, '0')}",
      )
      .lte(
        'date',
        "${cycleEnd.year.toString().padLeft(4, '0')}-"
        "${cycleEnd.month.toString().padLeft(2, '0')}-"
        "${cycleEnd.day.toString().padLeft(2, '0')}",
      );

double total = 0;

  for (var row in response) {
    if (row['deductions'] != null) {
      total += double.tryParse(row['deductions'].toString()) ?? 0;
    }
  }

print("TOTAL DEDUCTION = $total");
return total;

}
  Future<void> loadSavedSalary() async {
  final prefs = await SharedPreferences.getInstance();
final userId = selectedUserId;

  setState(() {
    totalNet = prefs.getDouble("total_salary_$userId") ?? 0;
    totalDeductionAll =
        prefs.getDouble("total_deduction_$userId") ?? 0;
  });
}

Future<void> loadMonthlyData() async {
  totalWorkedHours = 0;
    monthlyData.clear();
  chartMonths.clear();

final userId = selectedUserId;
  final now = DateTime.now();
if (joiningDate == null) return;


final cycleStart = getCycleStart(joiningDate!, now);

final cycleEnd = getCycleEnd(cycleStart);

final holidayResponse = await supabase
    .from('holidays')
    .select('holiday_date')
    .gte(
      'holiday_date',
      "${cycleStart.year.toString().padLeft(4, '0')}-"
      "${cycleStart.month.toString().padLeft(2, '0')}-"
      "${cycleStart.day.toString().padLeft(2, '0')}",
    )
    .lte(
      'holiday_date',
      "${cycleEnd.year.toString().padLeft(4, '0')}-"
      "${cycleEnd.month.toString().padLeft(2, '0')}-"
      "${cycleEnd.day.toString().padLeft(2, '0')}",
    );

List<String> holidays = holidayResponse
    .map<String>(
      (e) => e['holiday_date']
          .toString()
          .split('T')[0],
    )
    .toList();




int workingDays = 0;

for (
  DateTime d = cycleStart;
  !d.isAfter(cycleEnd);
  d = d.add(const Duration(days: 1))
){
  final dateStr =
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  bool isSunday =
      d.weekday == DateTime.sunday;

  bool isHoliday =
      holidays.contains(dateStr);

  if (!isSunday && !isHoliday) {
    workingDays++;
  }
}

monthlyTargetHours = workingDays * 8;


// 👇 AFTER THIS ONLY
final response = await supabase
    .from('attendance')
    .select()
    .eq('user_id', userId)
    .order('date');
 



  Map<String, double> earningsMap = {};
Map<String, double> deductionMap = {};

final role = employeeRole;

double monthlySalary =
    getSalaryByRole(employeeRole);


double perHour = monthlySalary / workingDays / 8;

  // ========================
  // 1️⃣ MONTHLY EARNINGS LOOP
  // ========================
  for (var row in response) {

final date = DateTime.parse(row['date']);

final cycleStart =
    getCycleStart(joiningDate!, date);

final cycleKey =
    "${cycleStart.year}-${cycleStart.month}-${cycleStart.day}";

final earned =
    double.tryParse(
      row['earned_amount']?.toString() ?? '0',
    ) ??
    0;

final deduction =
    double.tryParse(
      row['deductions']?.toString() ?? '0',
    ) ??
    0;

earningsMap[cycleKey] =
    (earningsMap[cycleKey] ?? 0) + earned;

deductionMap[cycleKey] =
    (deductionMap[cycleKey] ?? 0) + deduction;
     }

  // ========================
  // 2️⃣ TOTAL WORKED HOURS LOOP
  // ========================
  for (var row in response) {
  final rowDate = DateTime.parse(row['date']);

  // ✅ only current cycle hours
  if (rowDate.isBefore(cycleStart) ||
      rowDate.isAfter(cycleEnd)) {
    continue;
  }

  if (row['punch_in'] == null || row['punch_out'] == null) {
    continue;
  }

  final punchIn =
      DateTime.parse(row['punch_in']).toLocal();

  final punchOut =
      DateTime.parse(row['punch_out']).toLocal();

  double worked =
      punchOut.difference(punchIn).inMinutes / 60;

  totalWorkedHours += worked;
}

  // ========================
  // 3️⃣ CHART DATA
  // ========================
  List<Map<String, double>> tempData = [];
  List<int> tempMonths = [];

final keys = earningsMap.keys.toList()
  ..sort((a, b) => a.compareTo(b));

for (String key in keys) {
  final parts = key.split('-');
  final month = int.parse(parts[1]);

 final earnings = earningsMap[key] ?? 0;
final deduction = deductionMap[key] ?? 0;

tempData.add({
  "earnings": earnings,
  "deduction": deduction,
  "netSalary": earnings - deduction,
});

  tempMonths.add(month);
}
  if (tempData.isEmpty) {
    tempData.add({"earnings": 0, "deduction": 0});
    tempMonths.add(now.month);
  }

  if (tempData.length > 5) {
    tempData = tempData.sublist(tempData.length - 5);
    tempMonths = tempMonths.sublist(tempMonths.length - 5);
  }

  monthlyData = tempData;
  chartMonths = tempMonths;

  setState(() {});
}
Future<Map<String, dynamic>?> getTodayLeave() async {
final userId = selectedUserId;
  final today = getTodayDate(DateTime.now());

  final res = await supabase
      .from('leave_requests')
      .select()
      .eq('user_id', userId)
      .eq('status', 'approved')
      .lte('start_date', today)
      .gte('end_date', today)
      .maybeSingle();

  return res;
}
Future<void> createTodayAttendanceIfMissing() async {
final userId = selectedUserId;
  final todayDate = getTodayDate(DateTime.now());

  // ✅ first check leave
  final todayLeave = await getTodayLeave();

  // leave irundha attendance create panna venda
  if (todayLeave != null) return;

  final existing = await supabase
      .from('attendance')
      .select('id')
      .eq('user_id', userId)
      .eq('date', todayDate)
      .maybeSingle();

  if (existing == null) {
    final role = context.read<PunchProvider>().role;

  double monthlySalary =
    getSalaryByRole(employeeRole);

   final cycleStart = getCycleStart(joiningDate!, DateTime.now());
final cycleEnd = getCycleEnd(cycleStart);

final holidayResponse = await supabase
    .from('holidays')
    .select('holiday_date')
    .gte(
      'holiday_date',
      "${cycleStart.year.toString().padLeft(4, '0')}-"
      "${cycleStart.month.toString().padLeft(2, '0')}-"
      "${cycleStart.day.toString().padLeft(2, '0')}",
    )
    .lte(
      'holiday_date',
      "${cycleEnd.year.toString().padLeft(4, '0')}-"
      "${cycleEnd.month.toString().padLeft(2, '0')}-"
      "${cycleEnd.day.toString().padLeft(2, '0')}",
    );

List<String> holidays = holidayResponse
    .map<String>((e) => e['holiday_date'].toString().split('T')[0])
    .toList();

int payableDays = 30;

for (
  DateTime d = cycleStart;
  !d.isAfter(cycleEnd);
  d = d.add(const Duration(days: 1))
) {
  final dateStr =
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  bool isSunday = d.weekday == DateTime.sunday;
  bool isHoliday = holidays.contains(dateStr);

  if (isSunday || isHoliday) {
    payableDays--;
  }
}

double perDay = monthlySalary / payableDays;

    await supabase.from('attendance').insert({
      'user_id': userId,
      'date': todayDate,
      'punch_in': null,
      'punch_out': null,
      'earned_amount': 0,
      'deductions': perDay,
      'status': 'absent',
    });
  }
}
Future<void> calculateSalary() async {
     print("CALCULATE START");

  final now = DateTime.now();
  final todayDate = getTodayDate(now);
  final cycleStart = getCycleStart(joiningDate!, now);
final cycleEnd = getCycleEnd(cycleStart);
  final userId = selectedUserId;
   final role = context.read<PunchProvider>().role;
final todayLeave = await getTodayLeave();
double monthlySalary =
    getSalaryByRole(employeeRole);

int payableDays = 30;

for (
  DateTime d = cycleStart;
  !d.isAfter(cycleEnd);
  d = d.add(const Duration(days: 1))
) {
  if (d.weekday == DateTime.sunday) {
    payableDays--;
  }
}

double perDay = monthlySalary / payableDays;
double perHour = perDay / 8;

  final response = await supabase
    .from('attendance')
    .select('id,punch_in,punch_out,status,date,earned_amount,deductions')
    .eq('user_id', userId)
    .eq('date', todayDate);

  final attendance =
      response.isNotEmpty ? response.first : null;


// ✅ SAVE LEAVE FIRST
if (attendance == null && todayLeave != null) {
  final leaveType = todayLeave['leave_type'];

  await supabase.from('attendance').insert({
    'user_id': userId,
    'date': todayDate,
   'earned_amount': leaveType == 'paid' ? perDay : 0,
'deductions': leaveType == 'unpaid' ? perDay : 0,
    'status': 'leave',
  });

  await calculateSalary(); // refresh after insert
  return;
}

final cutoffTime = DateTime(
  now.year,
  now.month,
  now.day,
  11,
  0,
);


if (attendance == null &&
    todayLeave == null &&
    now.isAfter(cutoffTime))  {
  absentChecked = true;

  final existing = await supabase
      .from('attendance')
      .select('id')
      .eq('user_id', userId)
      .eq('date', todayDate)
      .maybeSingle();

  if (existing == null) {
    await supabase.from('attendance').insert({
      'user_id': userId,
      'date': todayDate,
      'punch_in': null,
      'punch_out': null,
      'earned_amount': 0,
      'deductions': perDay,
      'status': 'absent',
    });
  }
}

      

  // ❌ STOP IF REJECTED
  if (attendance != null && attendance['status'] == 'rejected') {
    setState(() {
      net = 0;
      grossSalary = 0;
      
      totalDeduction = 0;
      isLoading = false;
    });
    return;
  }

  double workedHours = 0;
  double lateHours = 0;
  double extraHours = 0;
  double leaveDeductionLocal = 0;

  
 

  // ================= PRESENT =================
  if (attendance != null && attendance['punch_in'] != null) {
    final punchIn = parsePunchIn(attendance['punch_in']);

    final startTime = DateTime(
      punchIn.year,
      punchIn.month,
      punchIn.day,
      9,
      30,
    );

    if (punchIn.isAfter(startTime)) {
      lateHours =
          punchIn.difference(startTime).inMinutes / 60.0;
    }

    if (attendance['punch_out'] != null) {
      final punchOut = parsePunchIn(attendance['punch_out']);
      workedHours =
          punchOut.difference(punchIn).inMinutes / 60.0;
    } else {
      workedHours =
          now.difference(punchIn).inMinutes / 60.0;
    }

    if (workedHours > 8) {
      extraHours = workedHours - 8;
    }
  } else {
  final isSunday = now.weekday == DateTime.sunday;

  if (!isSunday) {
    if (todayLeave != null) {
      // 🔥 LEAVE DAY
      if (todayLeave['leave_type'] == 'unpaid') {
        leaveDeductionLocal = perDay; // ✅ deduct only unpaid
      } else {
        leaveDeductionLocal = 0;      // ✅ paid leave → NO deduction
      }
    } else {
      // ❌ ABSENT (no punch + no leave)
      leaveDeductionLocal = perDay;
    }
  }
}
  double liveSessionHours = 0;

if (attendance != null && attendance['punch_in'] != null) {
  final punchIn = parsePunchIn(attendance['punch_in']);

  liveSessionHours =
      DateTime.now().difference(punchIn).inMinutes / 60;
}

  // ================= CALCULATION =================
  
 // ✅ Keep late & extra separate
double finalLateHours = lateHours;
double finalExtraHours = extraHours;

 double normalWork = workedHours;

if (normalWork > 8) normalWork = 8;
if (normalWork < 0) normalWork = 0;

   // ================= CALCULATION =================

// 1️⃣ Base earnings (late doesn't affect earning)
// 1️⃣ Base earning (late does NOT reduce base earning)
earnedToday = normalWork * perHour;

// 2️⃣ Total deduction (late + unpaid leave)
double totalDeductionToday =
    (finalLateHours * perHour) + leaveDeductionLocal;

// 3️⃣ Extra hour earning
double extraEarn = finalExtraHours * perHour;

// 4️⃣ Extra cancels deduction first
double remainingDeduction =
    totalDeductionToday - extraEarn;

// 5️⃣ Extra earning only after deduction becomes 0
double finalExtraEarning = 0;
if (remainingDeduction < 0) {
  finalExtraEarning = -remainingDeduction;
  remainingDeduction = 0;
}

// 6️⃣ Final Net
double finalNet =
    earnedToday + finalExtraEarning - remainingDeduction;

if (finalNet < 0) finalNet = 0;

// 7️⃣ Store deduction for UI / DB
totalDeduction = remainingDeduction;
double lateDeduction = finalLateHours * perHour;

  bool isWorkCompleted =
      attendance != null && attendance['punch_out'] != null;
    double currentTotal = totalWorkedHours;

if (attendance != null &&
    attendance['punch_in'] != null &&
    attendance['punch_out'] == null) {
  final punchIn = parsePunchIn(attendance['punch_in']);

  final live = DateTime.now()
      .difference(punchIn)
      .inMinutes / 60;

  currentTotal += live;
}


// ================= REMAINING HOURS FIX =================
// ================= REMAINING HOURS FIX =================
double adjustedWorked = totalWorkedHours;

final cycleAttendance = await supabase
    .from('attendance')
    .select('status,punch_in,punch_out,date')
    .eq('user_id', userId)
    .gte(
      'date',
      "${cycleStart.year.toString().padLeft(4, '0')}-"
      "${cycleStart.month.toString().padLeft(2, '0')}-"
      "${cycleStart.day.toString().padLeft(2, '0')}",
    )
    .lte(
      'date',
      "${cycleEnd.year.toString().padLeft(4, '0')}-"
      "${cycleEnd.month.toString().padLeft(2, '0')}-"
      "${cycleEnd.day.toString().padLeft(2, '0')}",
    );

for (var row in cycleAttendance) {
  final status = (row['status'] ?? '').toString().toLowerCase();

  if (status == 'leave' || status == 'absent') {
    adjustedWorked += 8;
  }
}

remainingHours = monthlyTargetHours - adjustedWorked;

if (remainingHours < 0) remainingHours = 0;
      

  // ================= STOP DOUBLE SALARY =================
final prefs = await SharedPreferences.getInstance();



double previousTotal = await loadCurrentCycleEarnedFromDB();

double previousDeduction =
    prefs.getDouble("total_deduction_$userId") ?? 0;





// ================= WORK COMPLETED =================
if (isWorkCompleted) {
  timer?.cancel();

  // prevent repeated update after punch out
  final dbEarned =
      double.tryParse(attendance['earned_amount']?.toString() ?? '0') ?? 0;

  if (dbEarned == 0) {
    await supabase
        .from('attendance')
        .update({
          'earned_amount':  earnedToday + finalExtraEarning,
          'deductions': remainingDeduction,
        })
        .eq('id', attendance['id']);
  }

  totalDeduction = remainingDeduction;

 previousTotal = await loadCurrentCycleEarnedFromDB();

  totalNet = previousTotal;

totalDeductionAll =
    await loadCurrentCycleDeductionFromDB();

totalNet =
    await loadCurrentCycleEarnedFromDB();


}


else if (attendance == null && todayLeave != null) {
  final leaveType = todayLeave['leave_type'];

  double earned = 0;
  double deduct = 0;

  if (leaveType == 'paid') {
  earned = perDay;   // save salary for paid leave
  deduct = 0;
} else {
  earned = 0;
  deduct = perDay;
}

  final existing = await supabase
      .from('attendance')
      .select('id')
      .eq('user_id', userId)
      .eq('date', todayDate)
      .maybeSingle();

  if (existing == null) {
    await supabase.from('attendance').insert({
      'user_id': userId,
      'date': todayDate,
      'earned_amount': earned,
      'deductions': deduct,
      'status': 'leave',
    });
  }

  earnedToday = earned;
  totalDeduction = deduct;
  totalDeductionAll = await loadCurrentCycleDeductionFromDB();
}
// ================= LIVE WORKING =================
else {

  



 totalDeduction = remainingDeduction;

 totalDeductionAll = await loadCurrentCycleDeductionFromDB();
}
grossSalary = monthlySalary;
 

  // ================= UI UPDATE =================
  setState(() {
    gross = "₹ ${grossSalary.toStringAsFixed(0)}";
    deduction = "₹ ${totalDeduction.toStringAsFixed(2)}";
    recentList = [
      {
        "icon": Icons.account_balance_wallet,
        "iconColor": Colors.green,
        "title": "Today Earnings",
        "subtitle": "${normalWork.toStringAsFixed(2)} hrs worked",
        "amount": "+ ₹${earnedToday.toStringAsFixed(2)}",
        "amountColor": Colors.green,
      },
      {
        "icon": Icons.access_time,
        "iconColor": Colors.orange,
        "title": "Late Punch",
        "subtitle": "${lateHours.toStringAsFixed(2)} hrs late",
        "amount": "₹${lateDeduction.toStringAsFixed(2)}",
        "amountColor": Colors.red,
      },
      {
        "icon": Icons.trending_up,
        "iconColor": Colors.blue,
        "title": "Extra Hours",
        "subtitle": "${finalExtraHours.toStringAsFixed(2)} hrs extra",
        "amount": "+ ₹${finalExtraEarning.toStringAsFixed(2)}",
        "amountColor": Colors.green,
      },
      {
        "icon": Icons.event_busy,
        "iconColor": Colors.red,
        "title": "Unpaid Leave",
        "subtitle": leaveDeductionLocal > 0 ? "Full day leave" : "No leave",
        "amount": "- ₹${leaveDeductionLocal.toStringAsFixed(2)}",
        "amountColor": Colors.red,
      },
     {
  "icon": Icons.hourglass_bottom,
  "iconColor": Colors.purple,
  "title": "Remaining Hours",
  "subtitle":
    "Target ${monthlyTargetHours.toStringAsFixed(0)} hrs/month",
  "amount": "${remainingHours.toStringAsFixed(2)} hrs",
  "amountColor": Colors.purple,
},
    ];

    isLoading = false;

    if (isWorkCompleted) {
      timer?.cancel(); 
    }
  });
}
@override
void initState() {
  super.initState();
  loadAllData();

    Future.delayed(const Duration(milliseconds: 500), () {
    calculateSalary();
  });
}

Future<void> loadAllData({bool refresh = false}) async {
  if (refresh) {
    setState(() => isRefreshing = true);
  } else {
    setState(() => isLoading = true);
  }

  joiningDate = await getJoiningDate();
  await loadMonthlyData();

  totalNet = await loadCurrentCycleEarnedFromDB();
  totalDeductionAll = await loadCurrentCycleDeductionFromDB();

  await calculateSalary();

  setState(() {
    isLoading = false;
    isRefreshing = false;
  });
}
 @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Container(
      color: Colors.white,
      child: isLoading
        
            ? const SalarySkeleton()
             : RefreshIndicator(
              onRefresh: () async {
                await loadAllData();
              },
              child :ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
       padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 140,
      ),
        children: [ Container(
         width: double.infinity,
         
      
      padding: const EdgeInsets.all(16,),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff1FA2FF),
            Color(0xff12D8FA)
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text("Net Salary",
              style: TextStyle(
                  color: Colors.white70)),
          SizedBox(
              height: size.height * 0.02),
          Text(
            "₹ ${totalNet.toStringAsFixed(0)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight:
                    FontWeight.bold),
          ),
          SizedBox(
              height: size.height * 0.02),
          Text(
            "Gross: $gross | Deduction: ₹${totalDeductionAll.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.white70),
          ),
        ],
      ),
        ),
        SizedBox(height: size.height * 0.02),
        Row(
      children: [
        Expanded(
          child: SmallCard(
            title: "Earnings",
            value: "+₹${earnedToday.toStringAsFixed(2)}",
            isGreen: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SmallCard(
            title: "Deduction",
            value: "-₹${totalDeduction.toStringAsFixed(2)}",
            isRed: true,
          ),
        ),
      ],
        ),SizedBox(height: size.height * 0.02),
       SectionCard(
  title: "6-Month Trend",
  child: SizedBox(
    height: 220, // 👈 PUT HERE
    child: SalaryBarChart(
      monthlyData: monthlyData,
      chartMonths: chartMonths,
    ),
  ),
),
        SizedBox(height: size.height * 0.02),
       SizedBox(
  child: Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: RecentRecords(records: recentList),
  ),
),
                   SizedBox( height:size.height*0.1),
            ]),)
      ),
    );
  }
} 