import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthsStats extends StatefulWidget {
  final String month;

  const MonthsStats({super.key, required this.month});

  @override
  State<MonthsStats> createState() => _MonthsStatsState();
}

class _MonthsStatsState extends State<MonthsStats> {
  final supabase = Supabase.instance.client;

  int getMonthNumber(String month) {
    const months = {
      "Jan": 1,
      "Feb": 2,
      "Mar": 3,
      "Apr": 4,
      "May": 5,
      "Jun": 6,
      "Jul": 7,
      "Aug": 8,
      "Sep": 9,
      "Oct": 10,
      "Nov": 11,
      "Dec": 12,
    };

    return months[month] ?? DateTime.now().month;
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {"attendance": [], "leave": []};

    final monthNumber = getMonthNumber(widget.month);
    final year = DateTime.now().year;

    final startDate = DateTime(year, monthNumber, 1);
    final endDate = DateTime(year, monthNumber + 1, 0);

    final attendance = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    final leave = await supabase
        .from('leave_requests')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .lte('start_date', endDate.toIso8601String().split('T')[0])
        .gte('end_date', startDate.toIso8601String().split('T')[0]);

    return {
      "attendance": List<Map<String, dynamic>>.from(attendance),
      "leave": List<Map<String, dynamic>>.from(leave),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "${widget.month} Attendance History",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: fetchData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dbRecords = snapshot.data!["attendance"]!;
                final leaveRecords = snapshot.data!["leave"]!;

                final monthNumber = getMonthNumber(widget.month);
                final year = DateTime.now().year;

                final now = DateTime.now();

                int totalDays = DateTime(year, monthNumber + 1, 0).day;

                if (year == now.year && monthNumber > now.month) {
                  totalDays = 0;
                } else if (year == now.year && monthNumber == now.month) {
                  totalDays = now.day;
                }

                return ListView.builder(
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    final currentDate = DateTime(year, monthNumber, index + 1);

                    final dateString = currentDate.toIso8601String().split(
                      'T',
                    )[0];

                    final record = dbRecords.firstWhere(
                      (e) => e['date'] == dateString,
                      orElse: () => {},
                    );

                    final leaveRecord = leaveRecords.firstWhere((leave) {
                      final start = DateTime.parse(leave['start_date']);
                      final end = DateTime.parse(leave['end_date']);
                      return !currentDate.isBefore(start) &&
                          !currentDate.isAfter(end);
                    }, orElse: () => {});

                    String status;
                    Color statusColor;
                    Color bgColor;

                    if (currentDate.weekday == DateTime.sunday) {
                      status = "Holiday";
                      statusColor = Colors.orange;
                      bgColor = Colors.orange.shade50;
                    } else if (leaveRecord.isNotEmpty) {
                      status = "Leave";
                      statusColor = Colors.blue;
                      bgColor = Colors.blue.shade50;
                    } else if (record.isNotEmpty &&
                        record['status'] == 'approved') {
                      status = "Present";
                      statusColor = Colors.green;
                      bgColor = Colors.green.shade50;
                    } else if (record.isNotEmpty &&
                        record['status'] == 'pending') {
                      status = "Pending";
                      statusColor = Colors.grey;
                      bgColor = Colors.grey.shade200;
                    } else {
                      status = "Absent";
                      statusColor = Colors.red;
                      bgColor = Colors.red.shade50;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${currentDate.day}-${currentDate.month}-${currentDate.year}",
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
