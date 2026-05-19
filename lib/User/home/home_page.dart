import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/AdminScreen/approval.dart';

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
import 'package:zeedz_attendance/provider/provider.dart';
import 'package:zeedz_attendance/widget/attendance_summary_section.dart';
import 'package:zeedz_attendance/widget/attendancechart.dart';
import 'package:zeedz_attendance/widget/summaryrowskeleton.dart';
import 'package:zeedz_attendance/widget/summer_card_widget.dart';
import 'package:zeedz_attendance/widget/summer_row_widget.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  bool isSummaryLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
 static bool isFirstLoad = true;
 
 Map<String, int> getCycleChart(PunchProvider punch) {
  final now = DateTime.now();
  final joiningDate = DateTime.parse(punch.joiningDate);
  final schedule = punch.workSchedule;

  int present = 0;
  int pending = 0;
  int leave = 0;
  int absent = 0;

  // ✅ SAME CYCLE LOGIC
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
  }

  final cycleStart = getCycleStart(joiningDate, now);
  final cycleEnd = cycleStart.add(const Duration(days: 29));

  bool isWorkingDay(DateTime d) {
    if (schedule == "mon_fri") {
      return d.weekday != DateTime.saturday &&
          d.weekday != DateTime.sunday;
    }
    return d.weekday != DateTime.sunday;
  }

  for (
    DateTime date = cycleStart;
    !date.isAfter(cycleEnd) && !date.isAfter(now);
    date = date.add(const Duration(days: 1))
  ) {
    if (!isWorkingDay(date) || punch.isHoliday(date)) continue;

    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final record = punch.attendanceList.where((item) {
      return item['date'].toString().substring(0, 10) == dateKey;
    }).toList();

    final leaveRecord = punch.leaveList.where((leaveItem) {
      final startLeave = DateTime.parse(leaveItem['start_date']);
      final endLeave = DateTime.parse(leaveItem['end_date']);

      return !date.isBefore(startLeave) &&
          !date.isAfter(endLeave);
    }).toList();

    if (leaveRecord.isNotEmpty) {
      leave++;
      continue;
    }

   if (record.isNotEmpty) {
  final row = record.first;
  final status = (row['status'] ?? '').toString().toLowerCase();
  final hasPunchIn = row['punch_in'] != null;

  if (hasPunchIn) {
    if (status == 'pending') {
      pending++;
    } else if (status == 'approved' || status == 'present') {
      present++;
    } else {
      absent++;
    }
  } else {
    absent++;
  }
}else {
      final today = DateTime(now.year, now.month, now.day);

      if (date.isBefore(today)) {
        absent++;
      } else {
        pending++;
      }
    }
  }

  return {
    "present": present,
    "absent": absent,
    "leave": leave,
    "pending": pending,
  };
}
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

    // ✅ Load data ONLY FIRST TIME
    if (isFirstLoad) {
      await _loadHomeData(provider);
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
  
Future<void> _loadHomeData(PunchProvider provider) async {
 if (isFirstLoad) {
  setState(() {
    isSummaryLoading = true;
     isFirstLoad = false;
  });
}

  // 🔥 IMPORTANT: clear old values first
 

  await provider.initializeApp();
 
  if (provider.role == 'superadmin' ||
      provider.role == 'admin' ||
      provider.role == 'hr') {
    await provider.loadSuperAdminStats();
    await provider.loadAllPendingCount();
  }

  if (!mounted) return;

  setState(() {
    isSummaryLoading = false;
     isFirstLoad = false;
  });
}bool isHolidayToday(List holidays) {
  final today = DateTime.now();
  final todayStr =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  return holidays.any((h) =>
      h['holiday_date'].toString().split("T")[0] == todayStr);
}

  @override
  Widget build(BuildContext context) {
 
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();
  final chart = getCycleChart(punch);
    if (isSummaryLoading && isFirstLoad) {
  return const WorkdayLoader();
}
    final role = punch.role;
    print("Total Absent Count: ${punch.totalAbsentEmployees}");

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<PunchProvider>();

          await provider.loadTodayPunch(); // ✅ only needed

          if (provider.role == 'admin' ||
              provider.role == 'hr' ||
              provider.role == 'superadmin') {
            await provider.loadSuperAdminStats();
            setState(() {});
          } // force UI rebuild
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
                builder: (_) => AttendanceApproval(hasBottomNav: false),
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
                              value: punch.todayLeaveEmployeesList.length
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
                                        hasBottomNav: false,
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
                            const Text(
                              "",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

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


AttendanceRadialChart(
  present: chart["present"] ?? 0,
  absent: chart["absent"] ?? 0,
  leave: chart["leave"] ?? 0,
  pending: chart["pending"] ?? 0,
)

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
  await _handlePunchIn(context);
} 
else if (status == "out") {
  await _handlePunchOut(context);
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

  Future<void> _handlePunchIn(BuildContext context) async {
    // if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    final picker = ImagePicker();

    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

  if (photo == null) {
  setState(() => isLoading = false);
  return;
}

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Location Disabled"),
            content: const Text("Please turn on your location to punch in."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                },
                child: const Text("Turn On"),
              ),
            ],
          ),
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
              "Location permission is permanently denied. Please enable it from settings.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String address =
          "${place.locality}, ${place.administrativeArea}, ${place.country}";

      await context.read<PunchProvider>().punchIn(address, context);
      await context.read<PunchProvider>().loadTodayPunch();

      // await context.read<PunchProvider>().loadAttendance();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Location Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; //  STOP LOADER
        });
      }
    }
  }
  
Future<void> _handlePunchOut(BuildContext context) async {
  print("👉 Punch Out button pressed");
  setState(() {
    isLoading = true;
  });

  final picker = ImagePicker();

  // 📸 OPEN CAMERA (NO SAVE)
  final XFile? photo = await picker.pickImage(source: ImageSource.camera);

  if (photo == null) {
    setState(() => isLoading = false);
    return;
  }

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Location Disabled"),
          content: const Text("Please turn on your location to punch out."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: const Text("Turn On"),
            ),
          ],
        ),
      );

      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text(
            "Location permission is permanently denied. Enable from settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );

      return;
    }

    // 📍 GET LOCATION (optional)
    final position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    String address =
        "${place.locality}, ${place.administrativeArea}, ${place.country}";

    // 🔥 ONLY CALL punchOut (NO IMAGE UPLOAD)
   try {
  await context.read<PunchProvider>().punchOut(context);
  print("✅ Punch out success");
} catch (e) {
  print("❌ Punch out error: $e");
}

    await context.read<PunchProvider>().loadTodayPunch();

  } catch (e) {
    print("PunchOut Error: $e");
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
}
