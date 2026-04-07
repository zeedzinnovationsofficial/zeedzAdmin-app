import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class LeaveApprovalPage extends StatefulWidget {
  const LeaveApprovalPage({super.key});

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  DateTime? startDate;
  DateTime? endDate;
  Set<int> expandedItems = {};
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> leaveFuture;
  String selectedFilter = 'all'; // dropdown filter
  @override
  void initState() {
    super.initState();
    loadLeaves();
  }

  void loadLeaves() {
    leaveFuture = supabase
        .from('leave_requests')
        .select(
          'id, user_id, reason, start_date, end_date, status, leave_type, reject_reason, approved_at, users!leave_requests_user_id_fkey(name)',
        )
        .order('created_at', ascending: false)
        .then((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final role = context.watch<PunchProvider>().role;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Requests"),
        centerTitle: true,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: _pickDateRange,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                icon: const Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("All")),
                  DropdownMenuItem(value: 'approved', child: Text("Approved")),
                  DropdownMenuItem(value: 'rejected', child: Text("Rejected")),
                  DropdownMenuItem(value: 'pending', child: Text("Pending")),
                  DropdownMenuItem(value: 'paid', child: Text("Paid Leave")),
                  DropdownMenuItem(
                    value: 'unpaid',
                    child: Text("Unpaid Leave"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final punch = context.read<PunchProvider>();

          await punch.loadTodayPunch();
        },
        child: FutureBuilder(
          future: leaveFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final leaves = List<Map<String, dynamic>>.from(
              snapshot.data as List,
            );

            //  FILTER LOGIC
            List<Map<String, dynamic>> filteredLeaves = leaves;

            /// STATUS FILTER
            if (selectedFilter != 'all') {
              if (selectedFilter == 'paid' || selectedFilter == 'unpaid') {
                // 👇 filter by leave_type
                filteredLeaves = filteredLeaves
                    .where((leave) => leave['leave_type'] == selectedFilter)
                    .toList();
              } else {
                // 👇 filter by status
                filteredLeaves = filteredLeaves
                    .where((leave) => leave['status'] == selectedFilter)
                    .toList();
              }
            }

            /// DATE RANGE FILTER
            if (startDate != null && endDate != null) {
              filteredLeaves = filteredLeaves.where((leave) {
                final start = DateTime.parse(leave['start_date']);
                final end = DateTime.parse(leave['end_date']);

                return start.isBefore(endDate!.add(const Duration(days: 1))) &&
                    end.isAfter(startDate!.subtract(const Duration(days: 1)));
              }).toList();
            }

            if (filteredLeaves.isEmpty) {
              return const Center(child: Text("No Leave Requests"));
            }

            return ListView.builder(
              itemCount: filteredLeaves.length,
              itemBuilder: (context, index) {
                final leave = filteredLeaves[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: AppColors.lightgrey, blurRadius: 2),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave['users']?['name'] ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: size.height * 0.01),

                      Text(
                        "Reason: ${leave['reason'] ?? '--'}",
                        maxLines: expandedItems.contains(index) ? null : 2,
                        overflow: expandedItems.contains(index)
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if ((leave['reason'] ?? '').length > 60)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (expandedItems.contains(index)) {
                                expandedItems.remove(index);
                              } else {
                                expandedItems.add(index);
                              }
                            });
                          },
                          child: Text(
                            expandedItems.contains(index)
                                ? "Show less"
                                : "Read more",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      SizedBox(height: size.height * 0.01),

                      Text(
                        "From: ${leave['start_date']}  To: ${leave['end_date']}",
                      ),

                      SizedBox(height: size.height * 0.01),

                      Text(
                        "Status: ${leave['status'].toString().toUpperCase()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: leave['status'] == 'approved'
                              ? Colors.green
                              : leave['status'] == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),

                      Text(
                        "Type: ${leave['leave_type'] ?? '--'}",
                        style: TextStyle(
                          color: leave['leave_type'] == ''
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // APPROVE / REJECT BUTTONS
                      if ((role == 'admin' || role == 'hr') &&
                          leave['status'] == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                String? leaveType = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Select Leave Type"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: const Text("Paid Leave"),
                                            onTap: () =>
                                                Navigator.pop(context, 'paid'),
                                          ),
                                          ListTile(
                                            title: const Text("Unpaid Leave"),
                                            onTap: () => Navigator.pop(
                                              context,
                                              'unpaid',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (leaveType != null) {
                                  await approveLeave(
                                    leave['id'],
                                    leave['user_id'],
                                    leaveType,
                                  );
                                }
                              },
                              child: const Text(
                                "Approve",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final TextEditingController rejectController =
                                    TextEditingController();

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Reject Leave"),
                                      content: TextField(
                                        controller: rejectController,
                                        decoration: const InputDecoration(
                                          hintText: "Enter reject reason",
                                        ),
                                        maxLines: 3,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final reason = rejectController.text
                                                .trim();
                                            if (reason.isEmpty) return;

                                            Navigator.pop(context);

                                            await rejectLeave(
                                              leave['id'],
                                              leave['user_id'],
                                              reason,
                                            );
                                          },
                                          child: const Text(
                                            "Submit",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                "Reject",
                                style: TextStyle(color: Colors.red),
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
    );
  }

  //  APPROVE
  Future<void> approveLeave(
    String leaveId,
    String userId,
    String leaveType,
  ) async {
    await supabase
        .from('leave_requests')
        .update({
          'status': 'approved',
          'leave_type': leaveType, // 👈 NEW
          'approved_by': supabase.auth.currentUser?.id,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', leaveId);

    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Leave Approved',
      'message': 'Your $leaveType leave has been approved.',
    });

    setState(() {
      loadLeaves(); // refresh
    });
  }

  //  REJECT
  Future<void> rejectLeave(
    String leaveId,
    String userId,
    String rejectReason,
  ) async {
    await supabase
        .from('leave_requests')
        .update({
          'status': 'rejected',
          'approved_by': supabase.auth.currentUser?.id,
          'approved_at': DateTime.now().toIso8601String(),
          'reject_reason': rejectReason,
        })
        .eq('id', leaveId);

    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Leave Rejected',
      'message': 'Your leave was rejected.\nReason: $rejectReason',
    });

    setState(() {});
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }
}
