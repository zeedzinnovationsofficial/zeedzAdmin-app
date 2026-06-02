import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalaryBarChart extends StatelessWidget {
  final List<Map<String, double>> monthlyData;
  final List<int> chartMonths;

  const SalaryBarChart({
    super.key,
    required this.monthlyData,
    required this.chartMonths,
  });
  

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty || chartMonths.isEmpty) {
  return const SizedBox(
    height: 200,
    child: Center(child: Text("No chart data")),
  );
}
    final size = MediaQuery.of(context).size;

    final now = DateTime.now();
    final currentMonth = now.month;

    // ---------------- FIX ORDER (CURRENT MONTH LAST) ----------------
    List<int> months = List.from(chartMonths);
    List<Map<String, double>> data = List.from(monthlyData);

    int index = months.indexOf(currentMonth);

    if (index != -1) {
      final m = months.removeAt(index);
      final d = data.removeAt(index);

      months.add(m);
      data.add(d);
    }

    final monthLabels =
        months.map((m) => _getMonthName(m)).toList();

    return SizedBox(
      height: size.height * 0.19,
      child: Padding(
       padding: const EdgeInsets.symmetric(horizontal: 10),
        child: BarChart(
  BarChartData(
    maxY: _getMaxY(data),

    barTouchData: BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipItem:
            (group, groupIndex, rod, rodIndex) {

          final item = data[group.x.toInt()];

          final netSalary =
    item['earnings'] ?? 0;

          final deduction =
              item['deduction'] ?? 0;

          return BarTooltipItem(
          "Net Salary : ₹${netSalary.toStringAsFixed(0)}\n"
"Deduction : ₹${deduction.toStringAsFixed(0)}",
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        },
      ),
    ),

    alignment: BarChartAlignment.spaceAround,

    borderData: FlBorderData(show: false),

    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 500,
    ),

    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();

            if (index < 0 ||
                index >= monthLabels.length) {
              return const SizedBox();
            }

            final isCurrent =
                months[index] == currentMonth;

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                monthLabels[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCurrent
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    ),

    barGroups: List.generate(months.length, (index) {

      final item = data[index];

     final earnings =
    item['earnings'] ?? 0;

      final deduction =
          item['deduction'] ?? 0;

      final isCurrent =
          months[index] == currentMonth;

      return BarChartGroupData(
        x: index,

        barsSpace: 4,

        barRods: [

          // Earnings Bar
          BarChartRodData(
            toY: earnings == 0 ? 1 : earnings,
            width: 10,
            color: isCurrent
                ? Colors.blueAccent
                : Colors.teal,
            borderRadius:
                BorderRadius.circular(6),
          ),

          // Deduction Bar
          BarChartRodData(
            toY: deduction == 0 ? 1 : deduction,
            width: 10,
            color: isCurrent
                ? Colors.redAccent
                : Colors.red,
            borderRadius:
                BorderRadius.circular(6),
          ),
        ],
      );
    }),
  ),
) ),
    );
  }

  BarChartGroupData _makeGroup(
    int x,
    double earnings,
    double deduction,
    bool isCurrent,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: earnings,
          width: 8,
          color: isCurrent ? Colors.blueAccent : Colors.teal,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: deduction,
          width: 8,
          color: isCurrent ? Colors.redAccent : Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
  double _getMaxY(List<Map<String, double>> data) {
  double max = 0;

  for (var item in data) {
    final e = item['earnings'] ?? 0;
    final d = item['deduction'] ?? 0;

    if (e > max) max = e;
    if (d > max) max = d;
  }

  return max == 0 ? 10 : max + 10;
}
}