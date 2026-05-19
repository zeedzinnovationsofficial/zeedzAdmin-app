import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeedz_attendance/widget/recentdetails.dart';
import 'package:zeedz_attendance/widget/salary_chart.dart';
import 'package:zeedz_attendance/widget/salaryskeleton.dart';
import 'package:zeedz_attendance/widget/sectioncard.dart';
import 'package:zeedz_attendance/widget/smallcard.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class SalaryDashboardPage extends StatefulWidget {
  
  const SalaryDashboardPage({super.key});

  @override
  State<SalaryDashboardPage> createState() =>
      _SalaryDashboardPageState();
}

class _SalaryDashboardPageState
    extends State<SalaryDashboardPage> {
     DateTime? joiningDate;
  final supabase = Supabase.instance.client;
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
      start.month,
      start.day,
    ).add(const Duration(days: 30));

    if (now.isBefore(next)) break;

    start = next;
  }

  return start;
} /// ✅ DATE FORMAT
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
  final userId = supabase.auth.currentUser!.id;

  final response = await supabase
      .from('users') // change if your table name differs
      .select('joining_date')
      .eq('id', userId)
      .single();

  return DateTime.parse(response['joining_date']);
}
  Future<double> loadCurrentCycleEarnedFromDB() async {
  final userId = supabase.auth.currentUser!.id;
  final now = DateTime.now();

  if (joiningDate == null) return 0;

  final cycleStart = getCycleStart(joiningDate!, now);
  final cycleEnd = cycleStart.add(const Duration(days: 29));

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
  final userId = supabase.auth.currentUser!.id;
  final now = DateTime.now();

  if (joiningDate == null) return 0;

  final cycleStart = getCycleStart(joiningDate!, now);
  final cycleEnd = cycleStart.add(const Duration(days: 29));

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
  final userId = supabase.auth.currentUser!.id;

  setState(() {
    totalNet = prefs.getDouble("total_salary_$userId") ?? 0;
    totalDeductionAll =
        prefs.getDouble("total_deduction_$userId") ?? 0;
  });
}

Future<void> loadMonthlyData() async {
  totalWorkedHours = 0;

  final userId = supabase.auth.currentUser!.id;
  final now = DateTime.now();
if (joiningDate == null) return;


final cycleStart = getCycleStart(joiningDate!, now);

final cycleEnd =
    cycleStart.add(const Duration(days: 29));

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
    .gte(
      'date',
      "${cycleStart.year}-${cycleStart.month.toString().padLeft(2, '0')}-${cycleStart.day.toString().padLeft(2, '0')}",
    )
    .order('date');
 



  Map<String, double> earningsMap = {};
Map<String, double> deductionMap = {};

final role = context.read<PunchProvider>().role;

double monthlySalary = getSalaryByRole(role);


double perHour = monthlySalary / 30 / 8;

  // ========================
  // 1️⃣ MONTHLY EARNINGS LOOP
  // ========================
  for (var row in response) {

  if (row['punch_in'] == null) continue;

  final date = DateTime.parse(row['date']);
final cycleStart = getCycleStart(joiningDate!, date);
final cycleKey =
    "${cycleStart.year}-${cycleStart.month}-${cycleStart.day}";

  DateTime punchIn =
      DateTime.parse(row['punch_in']).toLocal();

    if (row['punch_out'] == null) continue;

DateTime end =
    DateTime.parse(row['punch_out']).toLocal();

    double worked =
        end.difference(punchIn).inMinutes / 60;

    /// late
    final startMinutes = 9 * 60 + 30;
    final punchMinutes =
        punchIn.hour * 60 + punchIn.minute;

    double late = 0;
    if (punchMinutes > startMinutes) {
      late = (punchMinutes - startMinutes) / 60;
    }

    double earn = worked * perHour;
    double deduct = late * perHour;

    earningsMap[cycleKey] = (earningsMap[cycleKey] ?? 0) + earn;
deductionMap[cycleKey] = (deductionMap[cycleKey] ?? 0) + deduct;
  }

  // ========================
  // 2️⃣ TOTAL WORKED HOURS LOOP
  // ========================
  for (var row in response) {
    if (row['punch_in'] == null || row['punch_out'] == null) continue;

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

 final keys = earningsMap.keys.toList();

for (String key in keys) {
  final parts = key.split('-');
  final month = int.parse(parts[1]);

  tempData.add({
    "earnings": earningsMap[key] ?? 0,
    "deduction": deductionMap[key] ?? 0,
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
  final userId = supabase.auth.currentUser!.id;
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
  final userId = supabase.auth.currentUser!.id;
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

   double monthlySalary = getSalaryByRole(role);

    double perDay = monthlySalary / 30;

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
final cycleEnd = cycleStart.add(const Duration(days: 29));
  final userId = supabase.auth.currentUser!.id;
   final role = context.read<PunchProvider>().role;
final todayLeave = await getTodayLeave();
 double monthlySalary = getSalaryByRole(role);
  double perDay = monthlySalary / 30;  

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
    'earned_amount': 0,
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

  double perHour = monthlySalary / 30 / 8;
 

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

  totalDeduction =remainingDeduction;

  await supabase
      .from('attendance')
      .update({
        'earned_amount': finalNet,
        'deductions':  remainingDeduction
      })
      .eq('id', attendance['id']);

 previousTotal = await loadCurrentCycleEarnedFromDB();

  totalNet = previousTotal;

double cycleBase =
    await loadCurrentCycleDeductionFromDB();

double cycleExtra = 0;

final role = context.read<PunchProvider>().role;

double monthlySalary = getSalaryByRole(role);

double perHour = monthlySalary / 30 / 8;

final cycleResponse = await supabase
    .from('attendance')
    .select('punch_in,punch_out')
    .eq('user_id', userId);

for (var row in cycleResponse) {
  if (row['punch_in'] == null || row['punch_out'] == null) continue;

  final inTime = DateTime.parse(row['punch_in']).toLocal();
  final outTime = DateTime.parse(row['punch_out']).toLocal();

  double worked =
      outTime.difference(inTime).inMinutes / 60;

  double extra = worked > 8 ? (worked - 8) : 0;

  if (extra > 0) {
    cycleExtra += extra * perHour;
  }
}

totalDeductionAll =
    (cycleBase - cycleExtra).clamp(0, double.infinity);

  earnedToday = earnedToday + finalExtraEarning;
}


else if (attendance == null && todayLeave != null) {
  final leaveType = todayLeave['leave_type'];

  double earned = 0;
  double deduct = 0;

  if (leaveType == 'paid') {
    earned = 0;
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

  timer = Timer.periodic(
    const Duration(seconds: 5),
    (_) => calculateSalary(),
  );
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
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: isLoading
          ? const SalarySkeleton()
           : RefreshIndicator(
            onRefresh: () async {
              await loadAllData();
            },
            child :SingleChildScrollView(  physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                 width: double.infinity,
  margin: const EdgeInsets.only(top: 60), 
  
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
                    SmallCard(
                      title: "Earnings",
                      value: "+₹${earnedToday.toStringAsFixed(2)}",
                      isGreen: true,
                    ),
                    SmallCard(
                      title: "Deduction",
                      value:
                          "-₹${totalDeduction.toStringAsFixed(2)}",
                      isRed: true,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.02),
                SectionCard(
                  title: "6-Month Trend",
                  child:  SalaryBarChart(monthlyData: monthlyData, chartMonths:chartMonths),
                ),
                SizedBox(height: size.height * 0.02),
                RecentRecords(records: recentList),
                  SizedBox(height: size.height * 0.1)
              ],
            ),
          ),)
    );
  }
} 