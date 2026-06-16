import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AttendanceRadialChart extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;
  final int pending;

  const AttendanceRadialChart({
    super.key,
    required this.present,
    required this.absent,
    required this.leave,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Attendance Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

         Expanded(
          
  child: RepaintBoundary(
    child: PieChart(
         key: const ValueKey("attendance_chart"),
        
      PieChartData(
        centerSpaceRadius: 45,
        sectionsSpace: 4,
        sections: [
          PieChartSectionData(
            value: present.toDouble(),
            color: Colors.green,
            title: present.toString(),
            radius: 55,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: absent.toDouble(),
            color: Colors.red,
            title: absent.toString(),
            radius: 55,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: leave.toDouble(),
            color: Colors.blue,
            title: leave.toString(),
            radius: 55,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: pending.toDouble(),
            color:Colors.orange,
            title: pending.toString(),
            radius: 55,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
), const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _Legend(color: Colors.green, text: "Present"),
              _Legend(color: Colors.red, text: "Absent"),
              _Legend(color: Colors.blue, text: "Leave"),
              _Legend(color: Colors.orange, text: "Pending"),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}