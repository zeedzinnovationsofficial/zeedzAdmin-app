import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalaryPieChart extends StatelessWidget {
  const SalaryPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          sections: [
            PieChartSectionData(
              value: 65,
              color: Colors.teal,
              title: "65%",
              radius: 40,
            ),
            PieChartSectionData(
              value: 20,
              color: Colors.orange,
              title: "20%",
              radius: 40,
            ),
            PieChartSectionData(
              value: 10,
              color: Colors.green,
              title: "10%",
              radius: 40,
            ),
            PieChartSectionData(
              value: 5,
              color: Colors.red,
              title: "5%",
              radius: 40,
            ),
          ],
        ),
      ),
    );
  }
}