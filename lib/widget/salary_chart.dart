import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalaryBarChart extends StatelessWidget {
  const SalaryBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    /// 👉 Current month (0–11)
    final now = DateTime.now();
    final currentMonthIndex = now.month - 1;

    /// 👉 Generate last 5 months dynamically
    final months = List.generate(5, (i) {
      final month = DateTime(now.year, now.month - (4 - i));
      return _getMonthName(month.month);
    });

    return SizedBox(
      height: size.height * 0.19,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),

          /// 🔷 TITLES
          titlesData: FlTitlesData(
            leftTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),

            /// 🔥 MONTH LABELS
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= months.length) {
                    return const SizedBox();
                  }

                  /// 👉 Last index = current month
                  final isCurrent = index == 4;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      months[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            isCurrent ? Colors.black : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// 🔷 BAR DATA (5 months trend)
          barGroups: [
            _makeGroup(0, 2.5, 1, false),
            _makeGroup(1, 3, 1.2, false),
            _makeGroup(2, 4, 1.5, false),
            _makeGroup(3, 5, 2, false),
            _makeGroup(4, 6, 2.5, true), // 🔥 Current month
          ],
        ),
      ),
    );
  }

  /// 🔷 BAR GROUP
  BarChartGroupData _makeGroup(
      int x, double earnings, double deduction, bool isCurrent) {
    return BarChartGroupData(
      x: x,
      barRods: [
        /// 🔵 Earnings
        BarChartRodData(
          toY: earnings,
          width: 8,
          color: isCurrent ? Colors.blueAccent : Colors.teal,
          borderRadius: BorderRadius.circular(4),
        ),

        /// 🔴 Deduction
        BarChartRodData(
          toY: deduction,
          width: 8,
          color: isCurrent ? Colors.redAccent : Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// 🔷 Month Name Helper
  String _getMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}