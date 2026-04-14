import 'package:flutter/material.dart';
import 'package:zeedz_attendance/widget/recentdetails.dart';
import 'package:zeedz_attendance/widget/salary_chart.dart';
import 'package:zeedz_attendance/widget/salarypiechart.dart';
import 'package:zeedz_attendance/widget/sectioncard.dart';
import 'package:zeedz_attendance/widget/smallcard.dart';

class SalaryDashboardPage extends StatefulWidget {
  const SalaryDashboardPage({super.key});

  @override
  State<SalaryDashboardPage> createState() => _SalaryDashboardPageState();
}

class _SalaryDashboardPageState extends State<SalaryDashboardPage> {

  String netSalary = "\$3,240.00";
  String gross = "\$3,600";
  String deduction = "\$360";
  List<Map<String, dynamic>> recentList = [
  {
    "icon": Icons.account_balance_wallet,
    "iconColor": Colors.green,
    "title": "Base Salary",
    "subtitle": "Apr 2026",
    "amount": "+ ₹30,000.00",
    "amountColor": Colors.green,
  },

  {
    "icon": Icons.receipt_long,
    "iconColor": Colors.red,
    "title": "Tax Deduction",
    "subtitle": "Standard Rate",
    "amount": "- ₹1,200.00",
    "amountColor": Colors.red,
  },


   {
     "icon": Icons.event_busy,
     "iconColor": Colors.orange,
     "title": "Unpaid Leave",
     "subtitle": "2 days",
     "amount": "- ₹450.00",
     "amountColor": Colors.red,
   },
];

  @override
  void initState() {
    super.initState();

    
  }


  @override
  Widget build(BuildContext context) {
     final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
     
      body: Padding(
        padding: const EdgeInsets.only(top: 60,bottom: 90),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
        
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1FA2FF), Color(0xff12D8FA)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                   border: Border.all(
                   color: Colors.grey, // border color
                   width: size.width*0.002,            // border thickness
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Net Salary (Apr 2026)",
                        style: TextStyle(color: Colors.white70)),
                     SizedBox(height:size.height*0.02),
                    Text(netSalary,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                     SizedBox(height: size.height*0.02),
                    Text("Gross: $gross   |   Deductions: $deduction",
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
        
               SizedBox(height: size.height*0.02),
        
              /// 🔷 GRID
             
             Row(
              children: const [
                SmallCard(
                title: "Earnings",
                value: "+\$120",
                isGreen: true,
                ),
                SmallCard(
                title: "Leave Impact",
                value: "-\$45",
                isRed: true,
                ),
                ],
                ),
        
               SizedBox(height:  size.height*0.02),
        
             SectionCard(
              title: "6-Month Trend",
              child: const SalaryBarChart(),
              ),
        
              SectionCard(
              title: "Salary Composition",
              child: const SalaryPieChart(),
              ),
        
              SizedBox(height:  size.height*0.02),
             RecentRecords(records: recentList),
            ],
          ),
        ),
      ),
    );
  }

 
 
}