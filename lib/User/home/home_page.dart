import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/AdminScreen/approval.dart';
import 'package:zeedz_attendance/helper/punch_handler.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/absent_employees_page.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/employees_details_page.dart';
import 'package:zeedz_attendance/AdminScreen/organization%20overview/leave_employees_page.dart';
import 'package:zeedz_attendance/User/home/notification_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/home/widget/chat_bot.dart';
import 'package:zeedz_attendance/User/home/widget/chat_page.dart';

import 'package:zeedz_attendance/User/home/widget/loader.dart';
import 'package:zeedz_attendance/User/home/widget/punch_status_widget.dart';
import 'package:zeedz_attendance/User/home/widget/punching_widget.dart';
import 'package:zeedz_attendance/User/profile/profile_page.dart';
import 'package:zeedz_attendance/helper/home_chart_helper.dart';


import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/attendancechart.dart';
import 'package:zeedz_attendance/widget/attendancechartskeleton.dart';
import 'package:zeedz_attendance/widget/summaryrowskeleton.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> 
    with AutomaticKeepAliveClientMixin {
      @override
bool get wantKeepAlive => true;

  bool isLoading = false;
  Map<String, int> chartData = {};
  bool isSummaryLoading = true;
  bool isChartLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
 static bool isFirstLoad = true;
 
 
 @override
 
void initState() {
  super.initState();


  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final provider = context.read<PunchProvider>();

    // ✅ Load holidays
    final response = await Supabase.instance.client
        .from('holidays')
        .select();

    if (mounted) {
      setState(() {
        holidays = List<Map<String, dynamic>>.from(response);
      });
    }
  await _loadHomeData(provider);
    // ✅ Load data ONLY FIRST TIME
    if (isFirstLoad) {
    
    }
  });

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.preventDefault();
    event.notification.display();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(event.notification.title ?? "New Notification")),
    );
  });
}List<Map<String, dynamic>> holidays = [];
   bool get isHoliday => isHolidayToday(holidays);
   
  Future<void> _loadChart(PunchProvider provider) async {
  setState(() => isChartLoading = true);

  final chartMonth =
      (provider.role == 'employee' || provider.role == 'intern')
          ? DateTime.now()
          : selectedMonth;

  chartData = HomeChartHelper.getMonthlyChart(
    provider,
    chartMonth,
  );

  if (mounted) {
    setState(() => isChartLoading = false);
  }print("ROLE: ${provider.role}");
print("CHART MONTH: $chartMonth");
print("CHART DATA: $chartData");
}
Future<void> _loadHomeData(PunchProvider provider) async {
  if (isFirstLoad) {
    setState(() {
      isSummaryLoading = true;
      isChartLoading = true;
    });
  }
await provider.initializeApp();

if (provider.role == 'employee' || provider.role == 'intern') {
  final now = DateTime.now();

  await provider.loadMonthlyAttendance(
    DateTime(now.year, now.month),
  );
}

// 🔥 ADMIN / HR
if (provider.role == 'superadmin' ||
    provider.role == 'admin' ||
    provider.role == 'hr') {
  await provider.loadSuperAdminStats();
  await provider.loadAllPendingCount();
}

 

  // 🔥 IMPORTANT
  await _loadChart(provider);

  if (!mounted) return;

  setState(() {
    isSummaryLoading = false;
    isFirstLoad = false;
  });
}
bool isHolidayToday(List holidays) {
  final today = DateTime.now();
  final todayStr =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  return holidays.any((h) =>
      h['holiday_date'].toString().split("T")[0] == todayStr);
}


  @override
  Widget build(BuildContext context) {
  super.build(context);
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();
  
 final hasData = chartData.values.any((v) => v > 0);
    if (isSummaryLoading && isFirstLoad) {
  return const WorkdayLoader();
}
    final role = punch.role;
    print("Total Absent Count: ${punch.totalAbsentEmployees}");

    return Scaffold(
      body: RefreshIndicator(
 onRefresh: () async {
  final provider = context.read<PunchProvider>();

  await provider.initializeApp();

  if (provider.role == 'admin' ||
      provider.role == 'hr' ||
      provider.role == 'superadmin') {
    await provider.loadSuperAdminStats();
  }

  await _loadChart(provider); // 🔥 MUST


  setState(() {});
},
        child: Stack(
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.06),

                        /// ---------------- HEADER ----------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 12),

                                InkWell(
                                  borderRadius: BorderRadius.circular(50),
                                  onTap: role == 'employee' || role == 'intern'
                                      ? null // disable tap for employee
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ProfilePage(),
                                            ),
                                          );
                                        },
                                  child: CircleAvatar(
                                    radius: size.width * 0.08,
                                    backgroundColor: const Color.fromARGB(
                                      61,
                                      12,
                                      12,
                                      12,
                                    ),
                                    backgroundImage:
                                        punch.profileImageUrl.isNotEmpty
                                        ? NetworkImage(punch.profileImageUrl)
                                        : null,
                                    child: punch.profileImageUrl.isEmpty
                                        ? const Icon(Icons.person, size: 40)
                                        : null,
                                  ),
                                ),

                                SizedBox(width: size.width * 0.03),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      punch.name.isEmpty
                                          ? "Enter Name"
                                          : punch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.0),
                                    // Text(
                                    //   "ID: ${punch.employeeId ?? ''}",
                                    //   style: const TextStyle(
                                    //     fontSize: 13,
                                    //     fontWeight: FontWeight.bold,
                                    //   ),
                                    // ),
                                    Text(
                                      punch.role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: punch.role == 'superadmin'
                                            ? Colors.red
                                            : punch.role == 'admin'
                                            ? Colors.purple
                                            : punch.role == 'hr'
                                            ? Colors.orange
                                            : punch.role == 'employee'
                                            ? Colors.green
                                            : punch.role == 'intern'
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            ///  Notification ONLY FOR EMPLOYEE
                            if (role == 'employee' ||
                                role == 'admin' ||
                                role == 'hr' ||
                                role == 'intern')
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: StreamBuilder(
                                  stream: Supabase.instance.client
                                      .from('messages')
                                      .stream(primaryKey: ['id']),
                                  builder: (context, msgSnapshot) {
                                    return StreamBuilder(
                                      stream: Supabase.instance.client
                                          .from('notifications')
                                          .stream(primaryKey: ['id']),
                                      builder: (context, notifSnapshot) {
                                        int chatUnread = 0;
                                        int notifUnread = 0;

                                        final userId = Supabase
                                            .instance
                                            .client
                                            .auth
                                            .currentUser!
                                            .id;

                                        /// 🔥 CHAT COUNT
                                        if (msgSnapshot.hasData) {
                                          final data = msgSnapshot.data!;

                                          chatUnread = data.where((msg) {
                                            final seenBy = List.from(
                                              msg['seen_by'] ?? [],
                                            );
                                            return msg['sender_id'] != userId &&
                                                !seenBy.contains(userId);
                                          }).length;
                                        }

                                        /// 🔥 NOTIFICATION COUNT
                                        if (notifSnapshot.hasData) {
                                          final data = notifSnapshot.data!;

                                          notifUnread = data.where((n) {
                                            return n['user_id'] == userId &&
                                                n['is_read'] == false;
                                          }).length;
                                        }

                                        return Row(
                                          children: [
                                            /// 🔥 CHAT ICON
                                            Stack(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    CupertinoIcons
                                                        .paperplane_fill,
                                                    color: chatUnread > 0
                                                        ? Colors.red
                                                        : Colors.black,
                                                    size: 25,
                                                  ),
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ChatPage(),
                                                      ),
                                                    );
                                                  },
                                                ),

                                                if (chatUnread > 0)
                                                  Positioned(
                                                    right: 6,
                                                    top: 6,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: Text(
                                                        chatUnread > 9
                                                            ? '9+'
                                                            : chatUnread
                                                                  .toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            /// 🔔 NOTIFICATION ICON
                                            Stack(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.notifications,
                                                    size: 30,
                                                    color: notifUnread > 0
                                                        ? Colors.red
                                                        : Colors.black,
                                                  ),
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const NotificationPage(),
                                                      ),
                                                    );
                                                  },
                                                ),

                                                if (notifUnread > 0)
                                                  Positioned(
                                                    right: 6,
                                                    top: 6,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: Text(
                                                        notifUnread > 9
                                                            ? '9+'
                                                            : notifUnread
                                                                  .toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.02),

                        /// ================= SUPERADMIN DASHBOARD =================
                        if (role == 'superadmin') ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: size.height * 0.1),

                              /// MONTH SELECTOR + CALENDAR
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      "Organization Overview",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const Spacer(),

                                    // IconButton(
                                    //   icon: const Icon(Icons.calendar_month),
                                    //   onPressed: () async {
                                    //     final picked = await showDateRangePicker(
                                    //       context: context,
                                    //       firstDate: DateTime(2023),
                                    //       lastDate: DateTime.now(),
                                    //     );

                                    //     if (picked != null) {
                                    //       setState(() {
                                    //         startDate = picked.start;
                                    //         endDate = picked.end;
                                    //       });

                                    //       context
                                    //           .read<PunchProvider>()
                                    //           .loadStatsByRange(
                                    //             picked.start,
                                    //             picked.end,
                                    //           );
                                    //     }
                                    //   },
                                    // ),
                                  ],
                                ),
                              ),

                              SizedBox(height: size.height * 0.01),

                              /// MONTH LIST
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 12,
                                  itemBuilder: (context, index) {
                                    final monthDate = DateTime(
                                      DateTime.now().year,
                                      index + 1,
                                    );
                                    final isFuture = monthDate.isAfter(
                                      DateTime.now(),
                                    );

                                    final isSelected =
                                        selectedMonth.month ==
                                            monthDate.month &&
                                        selectedMonth.year == monthDate.year;

                                    return GestureDetector(
                                      onTap: isFuture
                                          ? null
                                          : () {
                                              setState(() {
                                                selectedMonth = monthDate;
                                                startDate = null;
                                                endDate = null;
                                              });

                                              context
                                                  .read<PunchProvider>()
                                                  .loadStatsByMonth(monthDate);
                                            },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.green
                                              : isFuture
                                              ? Colors.grey.shade200
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            [
                                              "Jan",
                                              "Feb",
                                              "Mar",
                                              "Apr",
                                              "May",
                                              "Jun",
                                              "Jul",
                                              "Aug",
                                              "Sep",
                                              "Oct",
                                              "Nov",
                                              "Dec",
                                            ][index],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: isFuture
                                                  ? Colors.grey
                                                  : isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                         SizedBox(height: size.height * 0.02),

isSummaryLoading
    ? const SummaryRowSkeleton()
    : SummaryRow(
        leftCard: SummaryCard(
          value: punch.totalEmployees.toString(),
          title: "Total Employees",
          valueColor: Colors.green,
          onTap: () {},
        ),
        rightCard: SummaryCard(
          value: punch.pendingCount.toString(),
          title: "Pending",
          valueColor: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceApproval(hasBottomNav: false, selectedMonth: selectedMonth,),
              ),
            );
          },
        ),
      ),

                          SizedBox(height: size.height * 0.015),
                          
                          SummaryRow(
                            leftCard: SummaryCard(
                              value: punch.totalAbsentEmployees.toString(),
                              title: "Absent ", //future absent count
                              valueColor: AppColors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AbsentEmployeesPage(
                                      month: selectedMonth,
                                    ),
                                  ),
                                );
                              },
                            ),
                            rightCard: SummaryCard(
                              value: punch.currentMonthLeaveEmployeesList.length.toString(),
                                  //future leave count
                              title: "On Leave",
                              valueColor: AppColors.royalblue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LeaveEmployeesPage(
                                      month: selectedMonth,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        /// ================= EMPLOYEE DASHBOARD =================
                        if (role == 'employee' ||
                            role == 'admin' ||
                            role == 'hr' ||
                            role == 'intern') ...[
                          PunchStatusCard(
                            statusText: punch.statusText,
                            inTime: punch.inTime,
                            outTime: punch.outTime,
                            workedHours: punch.formattedTotalHours,
                            punchInTime: punch.punchInTime,
                            isRunning: punch.isRunning,
                          ),

                          SizedBox(height: size.height * 0.02),

                          /// ================= ADMIN/HR DASHBOARD =================
                          if (role == 'admin' || role == 'hr') ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: size.height * 0.0),

                                /// MONTH SELECTOR + CALENDAR
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        "Organization Overview",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const Spacer(),

                                      // IconButton(
                                      //   icon: const Icon(Icons.calendar_month),
                                      //   onPressed: () async {
                                      //     final picked = await showDateRangePicker(
                                      //       context: context,
                                      //       firstDate: DateTime(2023),
                                      //       lastDate: DateTime.now(),
                                      //     );

                                      //     if (picked != null) {
                                      //       setState(() {
                                      //         startDate = picked.start;
                                      //         endDate = picked.end;
                                      //       });

                                      //       context
                                      //           .read<PunchProvider>()
                                      //           .loadStatsByRange(
                                      //             picked.start,
                                      //             picked.end,
                                      //           );
                                      //     }
                                      //   },
                                      // ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: size.height * 0.01),

                                /// MONTH LIST
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 12,
                                    itemBuilder: (context, index) {
                                      final monthDate = DateTime(
                                        DateTime.now().year,
                                        index + 1,
                                      );
                                      final isFuture = monthDate.isAfter(
                                        DateTime.now(),
                                      );

                                      final isSelected =
                                          selectedMonth.month ==
                                              monthDate.month &&
                                          selectedMonth.year == monthDate.year;

                                      return GestureDetector(
                                        onTap: isFuture
                                            ? null
                                            : () {
                                                setState(() {
                                                  selectedMonth = monthDate;
                                                  startDate = null;
                                                  endDate = null;
                                                });

                                                context
                                                    .read<PunchProvider>()
                                                    .loadStatsByMonth(
                                                      monthDate,
                                                    );
                                              },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.green
                                                : isFuture
                                                ? Colors.grey.shade200
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              [
                                                "Jan",
                                                "Feb",
                                                "Mar",
                                                "Apr",
                                                "May",
                                                "Jun",
                                                "Jul",
                                                "Aug",
                                                "Sep",
                                                "Oct",
                                                "Nov",
                                                "Dec",
                                              ][index],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isFuture
                                                    ? Colors.grey
                                                    : isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: size.height * 0.02),
                            punch.isLoaded?

                            SummaryRow(
                              leftCard: SummaryCard(
                                value: punch.totalEmployees.toString(),
                                title: "Total Employees",
                                valueColor: AppColors.green,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EmployeesDetailsPage(
                                        month: selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              rightCard: SummaryCard(
                                value: punch.totalPendingEmployees.toString(),
                                title: "Pending",
                                valueColor: AppColors.orange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceApproval(
                                        hasBottomNav: false, selectedMonth:selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ):const SummaryRowSkeleton(),

                            SizedBox(height: size.height * 0.015),
                            punch.isLoaded?
                            SummaryRow(
                              leftCard: SummaryCard(
                                value: punch.totalAbsentEmployees.toString(),
                                title: "Absent ", //future absent count
                                valueColor: AppColors.red,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AbsentEmployeesPage(
                                        month: selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              rightCard: SummaryCard(
                                value: punch.totalLeaveEmployees
                                    .toString(), //future leave count
                                title: "On Leave",
                                valueColor: AppColors.royalblue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LeaveEmployeesPage(
                                        month: selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ): const SummaryRowSkeleton(),
                          ],
                          if (role == 'employee' || role == 'intern') ...[
  //                           Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
                              

  //                             /// MONTH SELECTOR + CALENDAR
  //                             Padding(
  //                               padding: const EdgeInsets.symmetric(
  //                                 horizontal: 12,
  //                               ),
  //                               child: Row(
  //                                 children: [
  //                                   const Text(
  //                                     "Organization Overview",
  //                                     style: TextStyle(
  //                                       fontSize: 18,
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),

  //                                   const Spacer(),

  //                                   // IconButton(
  //                                   //   icon: const Icon(Icons.calendar_month),
  //                                   //   onPressed: () async {
  //                                   //     final picked = await showDateRangePicker(
  //                                   //       context: context,
  //                                   //       firstDate: DateTime(2023),
  //                                   //       lastDate: DateTime.now(),
  //                                   //     );

  //                                   //     if (picked != null) {
  //                                   //       setState(() {
  //                                   //         startDate = picked.start;
  //                                   //         endDate = picked.end;
  //                                   //       });

  //                                   //       context
  //                                   //           .read<PunchProvider>()
  //                                   //           .loadStatsByRange(
  //                                   //             picked.start,
  //                                   //             picked.end,
  //                                   //           );
  //                                   //     }
  //                                   //   },
  //                                   // ),
  //                                 ],
  //                               ),
  //                             ),

  //                             SizedBox(height: size.height * 0.01),

  //                             /// MONTH LIST
  //                             SizedBox(
  //                               height: 40,
  //                               child: ListView.builder(
  //                                 scrollDirection: Axis.horizontal,
  //                                 itemCount: 12,
  //                                 itemBuilder: (context, index) {
  //                                   final monthDate = DateTime(
  //                                     DateTime.now().year,
  //                                     index + 1,
  //                                   );
  //                                   final isFuture = monthDate.isAfter(
  //                                     DateTime.now(),
  //                                   );

  //                                   final isSelected =
  //                                       selectedMonth.month ==
  //                                           monthDate.month &&
  //                                       selectedMonth.year == monthDate.year;

  //                                   return GestureDetector(
  //                                     onTap: () async {
  // setState(() {
  //   selectedMonth = monthDate;
  // });

  // await context.read<PunchProvider>().loadStatsByMonth(monthDate);

  // setState(() {
  //   chartData = HomeChartHelper.getMonthlyChart(
  //     context.read<PunchProvider>(),
  //     monthDate,
  //   );
  // });

      

  //                                             context
  //                                                 .read<PunchProvider>()
  //                                                 .loadStatsByMonth(monthDate);
  //                                           },
  //                                     child: Container(
  //                                       margin: const EdgeInsets.symmetric(
  //                                         horizontal: 6,
  //                                       ),
  //                                       padding: const EdgeInsets.symmetric(
  //                                         horizontal: 14,
  //                                         vertical: 6,
  //                                       ),
  //                                       decoration: BoxDecoration(
  //                                         color: isSelected
  //                                             ? AppColors.green
  //                                             : isFuture
  //                                             ? Colors.grey.shade200
  //                                             : Colors.white,
  //                                         borderRadius: BorderRadius.circular(
  //                                           20,
  //                                         ),
  //                                         border: Border.all(
  //                                           color: Colors.grey.shade300,
  //                                         ),
  //                                       ),
  //                                       child: Center(
  //                                         child: Text(
  //                                           [
  //                                             "Jan",
  //                                             "Feb",
  //                                             "Mar",
  //                                             "Apr",
  //                                             "May",
  //                                             "Jun",
  //                                             "Jul",
  //                                             "Aug",
  //                                             "Sep",
  //                                             "Oct",
  //                                             "Nov",
  //                                             "Dec",
  //                                           ][index],
  //                                           style: TextStyle(
  //                                             fontWeight: FontWeight.w500,
  //                                             color: isFuture
  //                                                 ? Colors.grey
  //                                                 : isSelected
  //                                                 ? Colors.white
  //                                                 : Colors.black,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   );
  //                                 },
  //                               ),
  //                             ),
  //                           ],
  //                         ),

                         
                            SizedBox(height: size.height * 0.02),

                            // SummaryRow(
                            //   leftCard: SummaryCard(
                            //     value: punch.presentDays.toString(),
                            //     title: "Present",
                            //     valueColor: Colors.green,
                            //   ),
                            //   rightCard: SummaryCard(
                            //     value: punch.pendingDays.toString(),
                            //     title: "Pending",
                            //     valueColor: Colors.orange,
                            //   ),
                            // ),

                            // SizedBox(height: size.height * 0.015),

                            // SummaryRow(
                            //   leftCard: SummaryCard(
                            //     value: punch.absentDays.toString(),
                            //     title: "Absent",
                            //     valueColor: Colors.red,
                            //   ),
                            //   rightCard: SummaryCard(
                            //     value: punch.monthlyLeaveDays.toString(),
                            //     title: "Leave",
                            //     valueColor: Colors.orange,
                            //   ),
                            // ),



isChartLoading
    ? const AttendanceChartSkeleton()
    : hasData
        ? AttendanceRadialChart(
            key: ValueKey(chartData.toString()),
            present: chartData["present"] ?? 0,
            absent: chartData["absent"] ?? 0,
            leave: chartData["leave"] ?? 0,
            pending: chartData["pending"] ?? 0,
          )
        : const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "No attendance data for this month",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

                          ],
                          SizedBox(height: size.height * 0.03),

                         

 if (!isHoliday && punch.punchStatus != "leave"&&
    punch.punchStatus != "absent")
  Padding(
    padding: const EdgeInsets.all(12),
    child: PunchingWidget(
      isLoading: isLoading,
      punchStatus: punch.punchStatus,
     onTap: () async { print("STATUS: ${punch.punchStatus}");
 final status = punch.punchStatus.toLowerCase();

print("STATUS CLICKED: $status");

if (status == "approved" || status == "in") {
await PunchHandler.punchIn(context);
} 
else if (status == "out") {
 await PunchHandler.punchOut(context);
}
}
    ),
  )],
                        SizedBox(height: size.height * 0.18),
                      ],
                    ),
                  ),
            // Positioned(bottom: 80, right: 20, child: DraggableChatHead()),
            DraggableChatHead(),
          ],
        ),
      ),
    );
  }

 
}
