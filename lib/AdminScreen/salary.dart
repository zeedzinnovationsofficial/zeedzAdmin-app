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
  State<SalaryDashboardPage> createState() => _SalaryDashboardPageState();
}

class _SalaryDashboardPageState extends State<SalaryDashboardPage> {
  final supabase = Supabase.instance.client;

  int totalDays = 30;
  int sundays = 0;
  int holidays = 0;
  int unpaidLeaves = 0;

  double net = 0;
  double grossSalary = 0;
  double totalDeduction = 0;

  String gross = "₹0";
  String deduction = "₹0";

  List<Map<String, dynamic>> recentList = [];

  bool animateSalary = false;
  bool isLoading = true;

  Timer? timer;

  int getSundaysInMonth(int year, int month) {
    int count = 0;
    int daysInMonth = DateTime(year, month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      if (DateTime(year, month, i).weekday == DateTime.sunday) {
        count++;
      }
    }
    return count;
  }

  Future<int> fetchHolidays() async {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final response = await supabase
        .from('holidays')
        .select()
        .gte('holiday_date', start.toIso8601String())
        .lt('holiday_date', end.toIso8601String());

    return response.length;
  }

  Future<int> fetchUnpaidLeaves() async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', userId)
        .eq('status', 'approved')
        .eq('leave_type', 'unpaid');

    return response.length;
  }

  Future<void> calculateSalary() async {
    final role = context.read<PunchProvider>().role;

    double monthlySalary;

    if (role == 'intern') {
      monthlySalary = 3000;
    } else if (role == 'hr') {
      monthlySalary = 5000;
    } else {
      monthlySalary = 4000;
    }

    final now = DateTime.now();

    sundays = getSundaysInMonth(now.year, now.month);
    holidays = await fetchHolidays();
    unpaidLeaves = await fetchUnpaidLeaves();

    int workingDays = totalDays - sundays - holidays;
    if (workingDays <= 0) workingDays = 1;

    double perDay = monthlySalary / workingDays;
    double perHour = perDay / 8;

    /// 🔥 FETCH TODAY ATTENDANCE
    final todayDate = now.toIso8601String().split('T')[0];

    final attendance = await supabase
        .from('attendance')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('date', todayDate)
        .maybeSingle();

    double workedHours = 0;
    double lateHours = 0;

    if (attendance != null && attendance['punch_in'] != null) {
      final punchIn = DateTime.parse(attendance['punch_in']);

      workedHours = now.difference(punchIn).inMinutes / 60;

      double expectedStartHour = 9.0;
      double punchHour = punchIn.hour + (punchIn.minute / 60);

      if (punchHour > expectedStartHour) {
        lateHours = punchHour - expectedStartHour;
      }
    }

    /// 🔥 CALCULATION
    double earnedToday = workedHours * perHour;
    double lateDeduction = lateHours * perHour;
    double leaveDeduction = unpaidLeaves * perDay;

    totalDeduction = leaveDeduction + lateDeduction;
    net = earnedToday - lateDeduction;

    if (net < 0) net = 0;

    grossSalary = monthlySalary;

    setState(() {
      gross = "₹ ${grossSalary.toStringAsFixed(0)}";
      deduction = "₹ ${totalDeduction.toStringAsFixed(2)}";

      recentList = [
        {
          "icon": Icons.account_balance_wallet,
          "iconColor": Colors.green,
          "title": "Today Earnings",
          "subtitle": "${workedHours.toStringAsFixed(1)} hrs worked",
          "amount": "+ ₹${earnedToday.toStringAsFixed(2)}",
          "amountColor": Colors.green,
        },
        {
          "icon": Icons.access_time,
          "iconColor": Colors.orange,
          "title": "Late Punch",
          "subtitle": "${lateHours.toStringAsFixed(1)} hrs late",
          "amount": "- ₹${lateDeduction.toStringAsFixed(2)}",
          "amountColor": Colors.red,
        },
        {
          "icon": Icons.event_busy,
          "iconColor": Colors.red,
          "title": "Unpaid Leave",
          "subtitle": "$unpaidLeaves days",
          "amount": "- ₹${leaveDeduction.toStringAsFixed(2)}",
          "amountColor": Colors.red,
        },
      ];

      isLoading = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final alreadyAnimated = prefs.getBool("salary_animated") ?? false;

    if (!alreadyAnimated) {
      setState(() => animateSalary = true);
      await prefs.setBool("salary_animated", true);
    }
  }

  @override
  void initState() {
    super.initState();
    calculateSalary();

    /// 🔥 AUTO REFRESH
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      calculateSalary();
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
          : Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 90),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    /// SALARY CARD
                    Container(
                      width: double.infinity,
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
                          const Text("Net Salary",
                              style: TextStyle(color: Colors.white70)),
                          SizedBox(height: size.height * 0.02),

                          animateSalary
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: net),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, value, child) {
                                    return Text(
                                      "₹ ${value.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold),
                                    );
                                  },
                                )
                              : Text(
                                  "₹ ${net.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold),
                                ),

                          SizedBox(height: size.height * 0.02),
                          Text(
                            "Gross: $gross | Deduction: $deduction",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    Row(
                      children: [
                        SmallCard(
                          title: "Earnings",
                          value: "+₹${grossSalary.toStringAsFixed(0)}",
                          isGreen: true,
                        ),
                        SmallCard(
                          title: "Deduction",
                          value: "-₹${totalDeduction.toStringAsFixed(2)}",
                          isRed: true,
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    SectionCard(
                      title: "6-Month Trend",
                      child: const SalaryBarChart(),
                    ),

                    SizedBox(height: size.height * 0.02),

                    RecentRecords(records: recentList),
                  ],
                ),
              ),
            ),
    );
  }
}