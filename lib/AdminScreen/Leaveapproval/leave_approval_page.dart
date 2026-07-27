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

  List<Map<String, dynamic>> allLeaves = [];
  List<Map<String, dynamic>> filteredLeaves = [];

  String selectedFilter = 'all';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLeaves();
  }

  // ===================== LOAD ONCE =====================
  Future<void> loadLeaves() async {
    setState(() {
      isLoading = true;
    });

    final data = await supabase
        .from('leave_requests')
        .select(
          'id, user_id, reason, start_date, end_date, status, leave_type, reject_reason, approved_at, users!leave_requests_user_id_fkey(name)',
        )
        .order('created_at', ascending: false);

    allLeaves = List<Map<String, dynamic>>.from(data);

    applyFilters();

    setState(() {
      isLoading = false;
    });
  }

  // ===================== FILTER LOGIC =====================
  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(allLeaves);

    /// STATUS / TYPE FILTER
    if (selectedFilter != 'all') {
      if (selectedFilter == 'paid' || selectedFilter == 'unpaid') {
        temp = temp
            .where((leave) => leave['leave_type'] == selectedFilter)
            .toList();
      } else {
        temp = temp
            .where((leave) => leave['status'] == selectedFilter)
            .toList();
      }
    }

    /// DATE FILTER
    if (startDate != null && endDate != null) {
      temp = temp.where((leave) {
        final start = DateTime.parse(leave['start_date']);
        final end = DateTime.parse(leave['end_date']);

        return start.isBefore(endDate!.add(const Duration(days: 1))) &&
            end.isAfter(startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    filteredLeaves = temp;
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final role = context.watch<PunchProvider>().role;
  final now = DateTime.now();
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
                  DropdownMenuItem(value: 'unpaid', child: Text("Unpaid Leave")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                    applyFilters();
                  });
                },
              ),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await loadLeaves();
              },
              child: filteredLeaves.isEmpty
                  ? const Center(child: Text("No Leave Requests"))
                  : ListView.builder(
                    padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
                      itemCount: filteredLeaves.length,
                      itemBuilder: (context, index) {
                        final leave = filteredLeaves[index];

final startDate = DateTime.parse(leave['start_date']).toLocal();

final approvalCutoff = DateTime(
  startDate.year,
  startDate.month,
  startDate.day,
  10,
  0,
);

final canApprove = now.isBefore(approvalCutoff);
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
                              BoxShadow(
                                color: AppColors.lightgrey,
                                blurRadius: 2,
                              ),
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
                                  "Status: ${(!canApprove && leave['status'] == 'pending')      
                                  ? 'ABSENT'
                                   : leave['status'].toString().toUpperCase()}",
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
                                  "Type: ${(!canApprove && leave['status'] == 'pending')
                                    ? 'UNPAID'    
                                    : (leave['leave_type'] ?? '--')}",
                                style: TextStyle(
                                  color: leave['leave_type'] == ''
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                             



if ((role == 'admin' || role == 'hr' || role == 'superadmin') &&
    leave['status'] == 'pending' &&
    canApprove)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        String? leaveType =
                                            await showDialog<String>(
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
                                                    onTap: () =>
                                                        Navigator.pop(context, 'unpaid'),
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
                                            leaveType,);
                                        }
                                      },
                                      child: const Text(
                                        "Approve",
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),

                                    TextButton(
                                      onPressed: () async {
                                        final controller =
                                            TextEditingController();
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("Reject Leave"),
                                              content: TextField(
                                                controller: controller,
                                                maxLines: 3,
                                                decoration: const InputDecoration(
                                                  hintText: "Enter reject reason",
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final reason =
                                                        controller.text.trim();
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
                                                    style: TextStyle(
                                                        color: Colors.red),
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
                    ),
            ),
    );
  }

  // ===================== APPROVE =====================
Future<void> approveLeave(
  dynamic leaveId,
  String userId,
  String leaveType,
) async {

  // 👇 PUT HERE
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text("Processing leave approval...")
          ),
        ],
      ),
    ),
  );

  try {
      final supabase = Supabase.instance.client;

    final updated = await supabase .from('leave_requests')
     .update({ 'status': 'approved',
      'leave_type': leaveType,
       'approved_by': supabase.auth.currentUser!.id,
        'approved_at': DateTime.now().toIso8601String(),
         })
          .eq('id', leaveId)
           .select();
    if (updated.isEmpty) {
      throw Exception('Approval failed (check RLS or invalid id)');
    }
    final leave = await supabase .from('leave_requests') 
    .select('start_date, end_date')
     .eq('id', leaveId) 
     .single();
     double monthlySalary = await supabase
    .from('users')
    .select('salary')
    .eq('id', userId)
    .single()
    .then((value) => (value['salary'] ?? 0).toDouble());

final cycleStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
final cycleEnd = DateTime(
  DateTime.now().year,
  DateTime.now().month + 1,
  1,
).subtract(const Duration(days: 1));
final holidayResponse = await supabase
    .from('holidays')
    .select('holiday_date');

List<String> holidays = holidayResponse
    .map<String>((e) => e['holiday_date'].toString().split('T')[0])
    .toList();

int payableDays = 0;

for (DateTime d = cycleStart;
    !d.isAfter(cycleEnd);
    d = d.add(const Duration(days: 1))) {
  bool isSunday = d.weekday == DateTime.sunday;
  bool isHoliday = holidays.contains(
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");

  if (!isSunday && !isHoliday) {
    payableDays++;
  }
}

double perDayAmount =
    payableDays > 0 ? monthlySalary / payableDays : 0;
      final DateTime startDate = DateTime.parse(leave['start_date'])
      .toLocal();
       final DateTime endDate = DateTime.parse(leave['end_date'])
       .toLocal();
       for (DateTime d = startDate;
    !d.isAfter(endDate);
    d = d.add(const Duration(days: 1))) {

  final onlyDate = DateTime(d.year, d.month, d.day);

  final existing = await supabase
      .from('attendance')
      .select('id,status')
      .eq('user_id', userId)
      .eq(
  'date',
  "${onlyDate.year.toString().padLeft(4,'0')}-"
  "${onlyDate.month.toString().padLeft(2,'0')}-"
  "${onlyDate.day.toString().padLeft(2,'0')}"
)
      .maybeSingle();

  if (existing != null) {
    // 🔥 ALWAYS UPDATE (even if already absent)
    await supabase.from('attendance').update({
      'status': 'leave',
      'earned_amount': leaveType == 'paid' ? perDayAmount : 0,
'deductions': leaveType == 'unpaid' ? perDayAmount : 0,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', existing['id']);

  } else {
   print("INSERTING LEAVE");
print("userId = $userId");
print("date = $onlyDate");
print("status = leave");

await supabase.from('attendance').insert({
  'user_id': userId,
  'date':
      "${onlyDate.year.toString().padLeft(4, '0')}-"
      "${onlyDate.month.toString().padLeft(2, '0')}-"
      "${onlyDate.day.toString().padLeft(2, '0')}",
  'status': 'leave',
  'earned_amount': leaveType == 'paid' ? perDayAmount : 0,
  'deductions': leaveType == 'unpaid' ? perDayAmount : 0,
  'approved_at': DateTime.now().toIso8601String(),
});
  }
}
// 🔥 RELOAD DASHBOARD STATS
final provider = context.read<PunchProvider>();

await provider.loadStatsByMonth(
  DateTime.now(), // or selectedMonth if you pass it
);

await provider.loadSuperAdminStats(); // admin/hr dashboard counts
await supabase.from('notifications').insert({
  'user_id': userId,
  'title': 'Leave Approved',
  'message':
      'Your leave has been approved as ${leaveType == 'paid' ? 'Paid Leave' : 'Unpaid Leave'}.',
  'created_at': DateTime.now().toIso8601String(),
});
    await loadLeaves();

if (mounted) {
  Navigator.pop(context); // 👈 Close processing dialog

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Leave approved successfully'),
      backgroundColor: Colors.green,
    ),
  );
}
 } on PostgrestException catch (e) {
  

    if (mounted) {
          Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approve failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  // ===================== REJECT =====================
  Future<void> rejectLeave(
    dynamic leaveId,
    String userId,
    String rejectReason,
  ) async {
    
    await supabase.from('leave_requests').update({
      'status': 'rejected',
      'approved_by': supabase.auth.currentUser?.id,
      'approved_at': DateTime.now().toIso8601String(),
      'reject_reason': rejectReason,
    }).eq('id', leaveId);

    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Leave Rejected',
      'message': 'Your leave was rejected.\nReason: $rejectReason',
    });

    await loadLeaves();
  }

  // ===================== DATE PICK =====================
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
        applyFilters();
      });
    }
  }
}