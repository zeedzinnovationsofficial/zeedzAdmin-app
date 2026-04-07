import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';

Future<void> generateAttendancePdf(
  BuildContext context,
  DateTime start,
  DateTime end,
) async {

  final provider = context.read<PunchProvider>();

  final list = provider.attendanceList;

  int present = 0;
  int pending = 0;
  int leave = 0;
  int absent = 0;

  List<Map<String, dynamic>> filtered = [];

  for (var item in list) {

    if (item['punch_in'] == null) continue;

    final date = DateTime.parse(item['punch_in']).toLocal();

    if (date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)))) {

      filtered.add(item);

      final status = item['status'] ?? "pending";

      if (status == "approved") {
        present++;
      } else if (status == "pending") {
        pending++;
      } else if (status == "leave") {
        leave++;
      } else {
        absent++;
      }
    }
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              "Attendance Report",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "From: ${DateFormat('dd MMM yyyy').format(start)}",
            ),

            pw.Text(
              "To: ${DateFormat('dd MMM yyyy').format(end)}",
            ),

            pw.SizedBox(height: 20),

            pw.Text("Present: $present"),
            pw.Text("Pending: $pending"),
            pw.Text("Leave: $leave"),
            pw.Text("Absent: $absent"),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ["Date", "Punch In", "Punch Out", "Status"],
              data: filtered.map((e) {

                final date = DateTime.parse(e['punch_in']).toLocal();

                final punchOut = e['punch_out'] != null
                    ? DateFormat('hh:mm a').format(
                        DateTime.parse(e['punch_out']).toLocal(),
                      )
                    : "--";

                return [
                  DateFormat('dd MMM yyyy').format(date),
                  DateFormat('hh:mm a').format(date),
                  punchOut,
                  e['status'] ?? 'pending'
                ];
              }).toList(),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}