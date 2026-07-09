import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeedz_attendance/User/salary/salary_pdf_service.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:zeedz_attendance/widget/recentdetails.dart';
import 'package:zeedz_attendance/widget/salary_chart.dart';
import 'package:zeedz_attendance/widget/salaryskeleton.dart';
import 'package:zeedz_attendance/widget/sectioncard.dart';
import 'package:zeedz_attendance/widget/smallcard.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class SalaryDashboardPage extends StatefulWidget {
  final String? employeeId;
  const SalaryDashboardPage({super.key, this.employeeId});

  @override
  State<SalaryDashboardPage> createState() => _SalaryDashboardPageState();
}

class _SalaryDashboardPageState extends State<SalaryDashboardPage> {
  DateTime? joiningDate;
  final supabase = Supabase.instance.client;

 
  String get selectedUserId {
    return widget.employeeId ?? supabase.auth.currentUser!.id;
  }

  final pdfService = SalaryPdfService();
  late pw.Font notoFont;
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

  void startLiveSalaryTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        calculateSalary();
      },
    );
  }

  DateTime getCycleStart(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  DateTime getCycleEnd(DateTime now) {
    return DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
  }

  String getTodayDate(DateTime now) {
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  DateTime parsePunchIn(dynamic value) {
    final raw = value.toString();
    final dt = DateTime.parse(raw);
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  }
  
  Future<DateTime> getJoiningDate() async {
    final response = await supabase
        .from('users')
        .select('joining_date')
        .eq('id', selectedUserId)
        .single();
    return DateTime.parse(response['joining_date']);
  }

  Future<double> loadCurrentCycleEarnedFromDB() async {
    if (joiningDate == null) return 0;

    final cycleStart = getCycleStart(DateTime.now());
    final cycleEnd = getCycleEnd(DateTime.now());

    final response = await supabase
        .from('attendance')
        .select('earned_amount,date,status')
        .eq('user_id', selectedUserId)
        .gte('date', getTodayDate(cycleStart))
        .lte('date', getTodayDate(cycleEnd));

    double total = 0;
    for (var row in response) {
      total += double.tryParse(row['earned_amount'].toString()) ?? 0;
    }
    return total;
  }

  Future<double> loadCurrentCycleDeductionFromDB() async {
    if (joiningDate == null) return 0;

    final cycleStart = getCycleStart(DateTime.now());
    final cycleEnd = getCycleEnd(DateTime.now());

    final response = await supabase
        .from('attendance')
        .select('deductions')
        .eq('user_id', selectedUserId)
        .gte('date', getTodayDate(cycleStart))
        .lte('date', getTodayDate(cycleEnd));

    double total = 0;
    for (var row in response) {
      if (row['deductions'] != null) {
        total += double.tryParse(row['deductions'].toString()) ?? 0;
      }
    }
    return total;
  }

  Future<void> loadSavedSalary() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalNet = prefs.getDouble("total_salary_$selectedUserId") ?? 0;
      totalDeductionAll = prefs.getDouble("total_deduction_$selectedUserId") ?? 0;
    });
  }

  Future<void> loadMonthlyData() async {
    totalWorkedHours = 0;
    monthlyData.clear();
    chartMonths.clear();

    final now = DateTime.now();
    if (joiningDate == null) return;

    final cycleStart = getCycleStart(DateTime.now());
    final cycleEnd = getCycleEnd(DateTime.now());

    final holidayResponse = await supabase
        .from('holidays')
        .select('holiday_date')
        .gte('holiday_date', getTodayDate(cycleStart))
        .lte('holiday_date', getTodayDate(cycleEnd));

    List<String> holidays = holidayResponse
        .map<String>((e) => e['holiday_date'].toString().split('T')[0])
        .toList();

    int workingDays = 0;
    for (DateTime d = cycleStart; !d.isAfter(cycleEnd); d = d.add(const Duration(days: 1))) {
      final dateStr = getTodayDate(d);
      bool isSunday = d.weekday == DateTime.sunday;
      bool isHoliday = holidays.contains(dateStr);

      if (!isSunday && !isHoliday) {
        workingDays++;
      }
    }

    monthlyTargetHours = workingDays * 8;

    final response = await supabase
        .from('attendance')
        .select()
        .eq('user_id', selectedUserId)
        .order('date');

    Map<String, double> earningsMap = {};
    Map<String, double> deductionMap = {};

    double monthlySalary = await getUserSalary();
    double perHour = workingDays > 0 ? (monthlySalary / workingDays / 8) : 0;

    for (var row in response) {
      final date = DateTime.parse(row['date']);
      final cycleStartDateTime = DateTime(date.year, date.month, 1);
      final cycleKey = "${cycleStartDateTime.year}-${cycleStartDateTime.month}-${cycleStartDateTime.day}";

      final earned = double.tryParse(row['earned_amount']?.toString() ?? '0') ?? 0;
      final deductionVal = double.tryParse(row['deductions']?.toString() ?? '0') ?? 0;

      earningsMap[cycleKey] = (earningsMap[cycleKey] ?? 0) + earned;
      deductionMap[cycleKey] = (deductionMap[cycleKey] ?? 0) + deductionVal;
    }

    for (var row in response) {
      final rowDate = DateTime.parse(row['date']);
      if (rowDate.isBefore(cycleStart) || rowDate.isAfter(cycleEnd)) continue;
      if (row['punch_in'] == null || row['punch_out'] == null) continue;

      final punchIn = DateTime.parse(row['punch_in']).toLocal();
      final punchOut = DateTime.parse(row['punch_out']).toLocal();
      double worked = punchOut.difference(punchIn).inMinutes / 60;
      totalWorkedHours += worked;
    }

    List<Map<String, double>> tempData = [];
    List<int> tempMonths = [];

    if (joiningDate != null) {
      DateTime m = DateTime(joiningDate!.year, joiningDate!.month);
      while (!m.isAfter(DateTime.now())) {
        final key = "${m.year}-${m.month}-1";
        earningsMap.putIfAbsent(key, () => 0);
        deductionMap.putIfAbsent(key, () => 0);
        m = DateTime(m.year, m.month + 1);
      }
    }

    final keys = earningsMap.keys.toList()..sort((a, b) => a.compareTo(b));
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

    if (tempData.length > 6) {
      tempData = tempData.sublist(tempData.length - 6);
      tempMonths = tempMonths.sublist(tempMonths.length - 6);
    }

    monthlyData = tempData;
    chartMonths = tempMonths;
    setState(() {});
  }

  Future<Map<String, dynamic>?> getTodayLeave() async {
    final today = getTodayDate(DateTime.now());
    return await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', selectedUserId)
        .eq('status', 'approved')
        .lte('start_date', today)
        .gte('end_date', today)
        .maybeSingle();
  }

  Future<String> getEmployeeName() async {
    final res = await supabase.from('users').select('name').eq('id', selectedUserId).single();
    return res['name'] ?? '';
  }

  Future<String> getEmployeeId() async {
    final res = await supabase.from('users').select('employee_id').eq('id', selectedUserId).single();
    return res['employee_id'] ?? '';
  }

  Future<double> getUserSalary() async {
    final res = await supabase.from('users').select('salary').eq('id', selectedUserId).single();
    return (res['salary'] ?? 0).toDouble();
  }

  Future<void> createTodayAttendanceIfMissing() async {
    final todayDate = getTodayDate(DateTime.now());
    final todayLeave = await getTodayLeave();
    if (todayLeave != null) return;
final now = DateTime.now();

if (now.weekday == DateTime.sunday) {
  return;
}
    final existing = await supabase
        .from('attendance')
        .select('id')
        .eq('user_id', selectedUserId)
        .eq('date', todayDate)
        .maybeSingle();

    if (existing == null) {
      double monthlySalary = await getUserSalary();
      final cycleStart = getCycleStart(DateTime.now());
      final cycleEnd = getCycleEnd(DateTime.now());

      final holidayResponse = await supabase
          .from('holidays')
          .select('holiday_date')
          .gte('holiday_date', getTodayDate(cycleStart))
          .lte('holiday_date', getTodayDate(cycleEnd));

      List<String> holidays = holidayResponse
          .map<String>((e) => e['holiday_date'].toString().split('T')[0])
          .toList();

      int payableDays = 0;
      for (DateTime d = cycleStart; !d.isAfter(cycleEnd); d = d.add(const Duration(days: 1))) {
        final dateStr = getTodayDate(d);
        bool isSunday = d.weekday == DateTime.sunday;
        bool isHoliday = holidays.contains(dateStr);

        // ✅ பாசிட்டிவாக வேலை நாட்களைக் கணக்கிட (Fix 266 deduction)
        if (!isSunday && !isHoliday) {
          payableDays++;
        }
      }

      double perDay = payableDays > 0 ? (monthlySalary / payableDays) : 0;
      await supabase.from('attendance').insert({
        'user_id': selectedUserId,
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
    final now = DateTime.now();
    final todayDate = getTodayDate(now);
    final cycleStart = getCycleStart(DateTime.now());
    final cycleEnd = getCycleEnd(DateTime.now());
    
    final todayLeave = await getTodayLeave();
    double monthlySalary = await getUserSalary();

final cutoffTime = DateTime(now.year, now.month, now.day, 11, 0);
final isAfter11 = now.isAfter(cutoffTime);
    final holidayResponse = await supabase
        .from('holidays')
        .select('holiday_date')
        .gte('holiday_date', getTodayDate(cycleStart))
        .lte('holiday_date', getTodayDate(cycleEnd));

    List<String> holidays = holidayResponse
        .map<String>((e) => e['holiday_date'].toString().split('T')[0])
        .toList();

    int payableDays = 0;
    for (DateTime d = cycleStart; !d.isAfter(cycleEnd); d = d.add(const Duration(days: 1))) {
      final dateStr = getTodayDate(d);
      bool isSunday = d.weekday == DateTime.sunday;
      bool isHoliday = holidays.contains(dateStr);
      if (!isSunday && !isHoliday) {
        payableDays++;
      }
    }

    double perDay = payableDays > 0 ? (monthlySalary / payableDays) : 0;
    double perHour = perDay / 8;

    final response = await supabase
        .from('attendance')
        .select('id,punch_in,punch_out,status,date,earned_amount,deductions')
        .eq('user_id', selectedUserId)
        .eq('date', todayDate);

    final attendance = response.isNotEmpty ? response.first : null;

print("attendance = $attendance");
print("status = ${attendance?['status']}");
print("attendance id = ${attendance?['id']}");
print("perDay = $perDay");
    // 1️⃣ 🔥 LEAVE செக் லாஜிக் (Fix Paid/Unpaid Leave Database Bug)
    if (attendance != null && attendance['status'] == 'leave') {
      double earned = 0;
      double deduct = 0;

      final leaveRequest = await supabase
          .from('leave_requests')
          .select('leave_type')
          .eq('user_id', selectedUserId)
          .lte('start_date', todayDate)
          .gte('end_date', todayDate)
          .maybeSingle();

      final leaveType = leaveRequest?['leave_type'] ?? 'unpaid';
      
      // Paid leave என்றால் அன்றைய சம்பளம் முழுமையாகச் சேரும், Unpaid என்றால் கழிக்கப்படும்
      if (leaveType == 'paid') {
        earned = perDay;
        deduct = 0;
      } else {
        earned = 0;
        deduct = perDay;
      }

      // 🔄 Supabase டேட்டாபேஸில் தொகையைச் சரியாக அப்டேட் செய்கிறோம்
      await supabase
          .from('attendance')
          .update({'earned_amount': earned, 'deductions': deduct})
          .eq('id', attendance['id']);

      totalNet = await loadCurrentCycleEarnedFromDB();
      totalDeductionAll = await loadCurrentCycleDeductionFromDB();

      setState(() {
        earnedToday = earned;
        totalDeduction = deduct;
        gross = "₹ ${monthlySalary.toStringAsFixed(0)}";
        deduction = "₹ ${totalDeductionAll.toStringAsFixed(2)}";
        
       
      });
      
    }

    if (attendance != null && attendance['status'] == 'absent') {

  print("UPDATING ABSENT ROW");
print("attendance id = ${attendance['id']}");
print("perDay = $perDay");
  await supabase
      .from('attendance')
      .update({
        'earned_amount': 0,
        'deductions': perDay,
      })
      .eq('id', attendance['id']);

  totalDeduction = perDay;

  setState(() {
    earnedToday = 0;
    gross = "₹ ${monthlySalary.toStringAsFixed(0)}";
    deduction = "₹ ${totalDeduction.toStringAsFixed(2)}";
      isLoading = false;

  });

  
}
    if (attendance == null && todayLeave != null) {
      final leaveType = todayLeave['leave_type'];
      await supabase.from('attendance').insert({
        'user_id': selectedUserId,
        'date': todayDate,
        'earned_amount': leaveType == 'paid' ? perDay : 0,
        'deductions': leaveType == 'unpaid' ? perDay : 0,
        'status': 'leave',
      });
      await calculateSalary();
     
    }

    bool isSunday = now.weekday == DateTime.sunday;
    if (!isSunday &&
    attendance == null &&
    todayLeave == null &&
    now.isAfter(cutoffTime)) {
      absentChecked = true;
      final existing = await supabase
          .from('attendance')
          .select('id')
          .eq('user_id', selectedUserId)
          .eq('date', todayDate)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('attendance').insert({
          'user_id': selectedUserId,
          'date': todayDate,
          'punch_in': null,
          'punch_out': null,
          'earned_amount': 0,
          'deductions': perDay,
          'status': 'absent',
        });
      }
    }

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

if (isAfter11) {
  if (attendance == null || attendance['punch_in'] == null) {
    if (todayLeave != null) {
      leaveDeductionLocal =
          todayLeave['leave_type'] == 'unpaid' ? perDay : 0;
    } else {
      leaveDeductionLocal = perDay;
    }
  }
}

    if (attendance != null && attendance['punch_in'] != null) {
      final punchIn = parsePunchIn(attendance['punch_in']);
      final startTime = DateTime(punchIn.year, punchIn.month, punchIn.day, 9, 30);

      if (punchIn.isAfter(startTime)) {
        lateHours = punchIn.difference(startTime).inMinutes / 60.0;
      }

      if (attendance['punch_out'] != null) {
        final punchOut = parsePunchIn(attendance['punch_out']);
        workedHours = punchOut.difference(punchIn).inMinutes / 60.0;
      } else {
        workedHours = now.difference(punchIn).inMinutes / 60.0;
      }

      if (workedHours > 8) {
        extraHours = workedHours - 8;
      }
    } else {
      final isSunday = now.weekday == DateTime.sunday;
      if (!isSunday) {
        if (todayLeave != null) {
          leaveDeductionLocal = todayLeave['leave_type'] == 'unpaid' ? perDay : 0;
        } else {
          leaveDeductionLocal = perDay;
        }
      }
    }

    double normalWork = workedHours > 8 ? 8 : (workedHours < 0 ? 0 : workedHours);
    earnedToday = normalWork * perHour;

    double totalDeductionToday = (lateHours * perHour) + leaveDeductionLocal;
    double extraEarn = extraHours * perHour;
    double remainingDeduction = totalDeductionToday - extraEarn;

    double finalExtraEarning = 0;
    if (remainingDeduction < 0) {
      finalExtraEarning = -remainingDeduction;
      remainingDeduction = 0;
    }

    double finalNet = earnedToday + finalExtraEarning - remainingDeduction;
    if (finalNet < 0) finalNet = 0;

    context.read<PunchProvider>().setNetSalary(selectedUserId, finalNet);

    totalDeduction = isAfter11 ? remainingDeduction : 0;
    double lateDeduction = lateHours * perHour;

    bool isWorkCompleted = attendance != null && attendance['punch_out'] != null;
    double adjustedWorked = totalWorkedHours;

    final cycleAttendance = await supabase
        .from('attendance')
        .select('status,punch_in,punch_out,date')
        .eq('user_id', selectedUserId)
        .gte('date', getTodayDate(cycleStart))
        .lte('date', getTodayDate(cycleEnd));

    for (var row in cycleAttendance) {
      final status = (row['status'] ?? '').toString().toLowerCase();
      if (status == 'leave' || status == 'absent') {
        adjustedWorked += 8;
      }
    }

    remainingHours = monthlyTargetHours - adjustedWorked;
    if (remainingHours < 0) remainingHours = 0;

    if (isWorkCompleted) {
      timer?.cancel();
      await supabase.from('attendance').update({
        'earned_amount': (earnedToday + finalExtraEarning),
        'deductions': remainingDeduction,
      }).eq('id', attendance['id']);

      totalNet = await loadCurrentCycleEarnedFromDB();
      totalDeductionAll = await loadCurrentCycleDeductionFromDB();
    } else if (attendance != null && attendance['status'] == 'absent') {
      timer?.cancel(); 
      await supabase
          .from('attendance')
          .update({
            'earned_amount': 0,
            'deductions': remainingDeduction, 
          })
          .eq('id', attendance['id']);

      totalNet = await loadCurrentCycleEarnedFromDB();
      totalDeductionAll = await loadCurrentCycleDeductionFromDB();
    }
    
    grossSalary = monthlySalary;

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
          "subtitle": "${extraHours.toStringAsFixed(2)} hrs extra",
          "amount": "+ ₹${finalExtraEarning.toStringAsFixed(2)}",
          "amountColor": Colors.green,
        },
      if (todayLeave != null)
  {
    "icon": Icons.event_available,
    "iconColor": todayLeave['leave_type'] == 'paid'
        ? Colors.green
        : Colors.red,
    "title": todayLeave['leave_type'] == 'paid'
        ? "Paid Leave"
        : "Unpaid Leave",
    "subtitle": "Approved leave",
    "amount": todayLeave['leave_type'] == 'paid'
        ? "+ ₹${perDay.toStringAsFixed(2)}"
        : "- ₹${perDay.toStringAsFixed(2)}",
    "amountColor": todayLeave['leave_type'] == 'paid'
        ? Colors.green
        : Colors.red,
  }
else if (attendance != null && attendance['punch_in'] != null)
  {
    "icon": Icons.check_circle,
    "iconColor": Colors.green,
    "title": "Punched In",
    "subtitle": "Attendance marked",
    "amount": "₹0",
    "amountColor": Colors.green,
  }
else if (isAfter11)
  {
    "icon": Icons.event_busy,
    "iconColor": Colors.red,
    "title": "Unpaid Leave",
    "subtitle": "Not Punched In ",
    "amount": "- ₹${leaveDeductionLocal.toStringAsFixed(2)}",
    "amountColor": Colors.red,
  }
else
  {
    "icon": Icons.access_time,
    "iconColor": Colors.orange,
    "title": "Not Punched In",
    "subtitle": "Waiting for punch in",
    "amount": "₹0",
    "amountColor": Colors.orange,
  },
        {
          "icon": Icons.hourglass_bottom,
          "iconColor": Colors.purple,
          "title": "Remaining Hours",
          "subtitle": "Target ${monthlyTargetHours.toStringAsFixed(0)} hrs/month",
          "amount": "${remainingHours.toStringAsFixed(2)} hrs",
          "amountColor": Colors.purple,
        },
      ];
      isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    loadAllData();
    startLiveSalaryTimer();
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

    context.read<PunchProvider>().setNetSalary(selectedUserId, totalNet);

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
      backgroundColor: Colors.white,
      body: isLoading
          ? const SalarySkeleton()
          : RefreshIndicator(
              onRefresh: () async {
                await loadAllData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Salary",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.download_for_offline_outlined,
                              color: Colors.black,
                              size: 30,
                            ),
                            onPressed: () async {
                              if (joiningDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Loading employee data...")),
                                );
                                return;
                              }

                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: joiningDate!,
                                lastDate: DateTime.now(),
                                helpText: "Select Salary Range",
                              );

                              if (picked == null) return;

                              final start = picked.start;
                              final end = picked.end;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Download Salary PDF"),
                                  content: Text(
                                    "From ${start.day}-${start.month}-${start.year}\n"
                                    "To ${end.day}-${end.month}-${end.year}",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Download"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              final data = await pdfService.getAttendanceForPdf(
                                userId: selectedUserId,
                                start: start,
                                end: end,
                                supabase: Supabase.instance.client,
                              );

                              final employeeName = await getEmployeeName();
                              final employeeId = await getEmployeeId();
                              await pdfService.loadFont();
                              await pdfService.generateAttendancePdf(
                                attendanceData: data,
                                joiningDate: joiningDate!,
                                employeeName: employeeName,
                                employeeId: employeeId,
                                startDate: start,
                                endDate: end,
                                context: context,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("PDF downloaded successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff1FA2FF), Color(0xff12D8FA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Net Salary", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        SizedBox(height: size.height * 0.001),
                        Text(
                          "₹ ${totalNet.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          "Gross: $gross | Deduction: ₹${totalDeductionAll.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white70),
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
                  ),
                  SizedBox(height: size.height * 0.02),
                  SectionCard(
                    title: "6-Month Trend",
                    child: SizedBox(
                      height: 220,
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
                  SizedBox(height: size.height * 0.1),
                ]),
              ),
            ),
    );
  }
}