import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class AttendanceApproval extends StatefulWidget {
  final bool hasBottomNav; 
  const AttendanceApproval({super.key, required this.hasBottomNav});

  @override
  State<AttendanceApproval> createState() => _AdminPageState();
}

class _AdminPageState extends State<AttendanceApproval> {
  DateTime? startDate;
  DateTime? endDate;
  late Future<List<Map<String, dynamic>>> attendanceFuture;
  final supabase = Supabase.instance.client;
  @override
  void initState() {
    super.initState();
    attendanceFuture = fetchAttendance();
  }

  Set<dynamic> selectedIds = {};
  bool selectAll = false;
  Future<List<Map<String, dynamic>>> fetchAttendance() async {
    var query = supabase.from('attendance').select().eq('status', 'pending');

    if (startDate != null && endDate != null) {
      query = query
          .gte('date', startDate!.toIso8601String().split('T')[0])
          .lte('date', endDate!.toIso8601String().split('T')[0]);
    } else {
      final now = DateTime.now();
      query = query.lte('date', now.toIso8601String().split('T')[0]);
    }

    final attendance = await query.order('date', ascending: false);

    List<Map<String, dynamic>> finalData = [];

    for (var record in attendance) {
      final userData = await supabase
          .from('users')
          .select('name')
          .eq('id', record['user_id'])
          .maybeSingle();

      finalData.add({
        'id': record['id'],
        'user_id': record['user_id'],
        'name': userData?['name'] ?? "Unknown",
        'date': record['date'],
        'punch_in': record['punch_in'],
        'punch_out': record['punch_out'],
        'location': record['location'],
      });
    }

    return finalData;
  }

  String formatAttendanceDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    final weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final month = [
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
    ];

    if (target == today) {
      return "Today";
    } else if (target == yesterday) {
      return "Yesterday";
    } else {
      return "${date.day} ${month[date.month - 1]} ${weekday[date.weekday - 1]}";
    }
  }

  String formatTime(String? time) {
    if (time == null) return "--";
    final dt = DateTime.parse(time);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<PunchProvider>().role;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<PunchProvider>().loadTodayPunch();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),

              /// TITLE + SELECT ALL
              FutureBuilder<List<Map<String, dynamic>>>(
                future: attendanceFuture,
                builder: (context, snapshot) {
                  final attendance = snapshot.data ?? [];

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (Navigator.canPop(context))
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            )
                          else
                            SizedBox(width: size.width * 0.01),

                          const Text(
                            "Today Attendance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Text("Select All"),
                              Checkbox(
                                value: selectAll,
                                onChanged: (value) {
                                  setState(() {
                                    selectAll = value ?? false;
                                    selectedIds.clear();

                                    if (selectAll) {
                                      for (var item in attendance) {
                                        if (item['punch_in'] != null &&
                                            item['punch_out'] != null) {
                                          selectedIds.add(item['id']);
                                        }
                                      }
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // SizedBox(width: size.width * 0.78),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _pickDateRange,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              /// BULK ACTION BUTTONS
              if (selectedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shadowgreen,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: approveSelected,
                          child: const Text(
                            "Approve All",
                            style: TextStyle(color: AppColors.green),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.1),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shadowred,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: showBulkRejectDialog,
                          child: const Text(
                            "Reject All",
                            style: TextStyle(color: AppColors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              /// LIST
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchAttendance(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final attendance = snapshot.data ?? [];

                    if (attendance.isEmpty) {
                      return const Center(child: Text("No Pending Attendance"));
                    }

                    return ListView.builder(
                      itemCount: attendance.length,
                      itemBuilder: (context, index) {
                        final data = attendance[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lightgrey,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Checkbox
                              if (selectAll)
                                Checkbox(
                                  value: selectedIds.contains(data['id']),
                                  onChanged: (value) {
                                    if (data['punch_in'] != null &&
                                        data['punch_out'] != null) {
                                      setState(() {
                                        if (value == true) {
                                          selectedIds.add(data['id']);
                                        } else {
                                          selectedIds.remove(data['id']);
                                          selectAll = false;
                                        }
                                      });
                                    }
                                  },
                                ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        formatAttendanceDate(data['date']),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (role.toLowerCase() == 'hr' ||
                                          role.toLowerCase() == 'admin' ||
                                          role.toLowerCase() == 'superadmin')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () => showEditDialog(data),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.01),

                              Text(
                                "Punch In: ${formatTime(data['punch_in'])}",
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                "Punch Out: ${formatTime(data['punch_out'])}",
                                style: TextStyle(
                                  color: data['punch_out'] != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),

                              SizedBox(height: size.height * 0.01),
                              Text("Location: ${data['location'] ?? '--'}"),

                              SizedBox(height: size.height * 0.02),

                              if (role != 'employee')
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.shadowgreen,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        onPressed: (data['punch_out'] == null)
                                            ? null
                                            : () =>
                                                  approveAttendance(data['id']),
                                        child: const Text(
                                          "Approve",
                                          style: TextStyle(
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: size.width * 0.05),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.shadowred,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        onPressed: () =>
                                            showRejectDialog(data['id']),
                                        child: const Text(
                                          "Reject",
                                          style: TextStyle(
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            if (widget.hasBottomNav)
  SizedBox(height: size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  /// APPROVE SINGLE
  Future<void> approveAttendance(dynamic id) async {
    await supabase
        .from('attendance')
        .update({
          'status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    setState(() {
      attendanceFuture = fetchAttendance();
    });
  }

  /// REJECT SINGLE
  Future<void> rejectAttendance(dynamic id, String reason) async {
    await supabase
        .from('attendance')
        .update({
          'status': 'rejected',
          'reject_reason': reason,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    setState(() {
      attendanceFuture = fetchAttendance();
    });
  }

  /// APPROVE BULK
  Future<void> approveSelected() async {
    for (var id in selectedIds) {
      await supabase
          .from('attendance')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }

    setState(() {
      selectedIds.clear();
      selectAll = false;
      attendanceFuture = fetchAttendance();
    });
  }

  /// REJECT BULK
  Future<void> rejectSelected(String reason) async {
    for (var id in selectedIds) {
      await supabase
          .from('attendance')
          .update({
            'status': 'rejected',
            'reject_reason': reason,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }

    setState(() {
      selectedIds.clear();
      selectAll = false;
      attendanceFuture = fetchAttendance();
    });
  }

  void showRejectDialog(dynamic id) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Attendance"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter reject reason"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              rejectAttendance(id, reason);
            },
            child: const Text("Submit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showBulkRejectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Selected"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter reject reason"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              rejectSelected(reason);
            },
            child: const Text("Submit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        attendanceFuture = fetchAttendance();
      });
    }
  }

  void showEditDialog(Map<String, dynamic> data) {
    TimeOfDay? punchIn = data['punch_in'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(data['punch_in']))
        : null;

    TimeOfDay? punchOut = data['punch_out'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(data['punch_out']))
        : null;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Attendance"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔹 PUNCH IN
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: punchIn ?? TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          punchIn = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          /// TEXT
                          Expanded(
                            child: Text(
                              punchIn == null
                                  ? "Select Punch In"
                                  : "Punch In : ${punchIn!.format(context)}",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),

                          /// ICON
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),

                  /// 🔹 PUNCH OUT
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: punchOut ?? TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          punchOut = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          /// TEXT
                          Expanded(
                            child: Text(
                              punchOut == null
                                  ? "Select Punch Out"
                                  : "Punch Out : ${punchOut!.format(context)}",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),

                          /// ICON
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                TextButton(
                  onPressed: () async {
                    await updateAttendance(
                      data['id'],
                      data['date'],
                      punchIn,
                      punchOut,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateAttendance(
    dynamic id,
    String date,
    TimeOfDay? punchIn,
    TimeOfDay? punchOut,
  ) async {
    final existing = await supabase
        .from('attendance')
        .select('punch_in, punch_out')
        .eq('id', id)
        .single();

    String? punchInTime = existing['punch_in'];
    String? punchOutTime = existing['punch_out'];

    if (punchIn != null) {
      final dt = DateTime.parse(date);
      final newTime = DateTime(
        dt.year,
        dt.month,
        dt.day,
        punchIn.hour,
        punchIn.minute,
      );
      punchInTime = newTime.toIso8601String();
    }

    if (punchOut != null) {
      final dt = DateTime.parse(date);
      final newTime = DateTime(
        dt.year,
        dt.month,
        dt.day,
        punchOut.hour,
        punchOut.minute,
      );
      punchOutTime = newTime.toIso8601String();
    }

    await supabase
        .from('attendance')
        .update({
          'punch_in': punchInTime,
          'punch_out': punchOutTime,
          'status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    setState(() {
      attendanceFuture = fetchAttendance();
    });

    /// refresh employee UI
    await context.read<PunchProvider>().loadTodayPunch();
  }
}
