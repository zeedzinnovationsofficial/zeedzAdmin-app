import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class SalaryPdfService {
  pw.Font? notoFont;

 Future<void> loadFont() async {
  try {
    final data =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');

    print("Font loaded: ${data.lengthInBytes}");

    notoFont = pw.Font.ttf(data);
  } catch (e) {
    print("Font error: $e");
  }
}

  Map<String, List<Map<String, dynamic>>> groupByMonth(
      List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var row in data) {
      final date = DateTime.parse(row['date']);
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(row);
    }

    return grouped;
  }

 Future<void> generateAttendancePdf({
    required BuildContext context,
  required List<Map<String, dynamic>> attendanceData,
  required String employeeName,
   required DateTime joiningDate,
  required String employeeId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
    final pdf = pw.Document();

    final boldStyle = pw.TextStyle(
      font: notoFont,
      fontWeight: pw.FontWeight.bold,
    );

    final textStyle = pw.TextStyle(font: notoFont);

    final grouped = groupByMonth(attendanceData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
          
  pw.Text(
    "Salary Report",
    style: pw.TextStyle(
      font: notoFont,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    ),
  ),

  pw.SizedBox(height: 10),

  pw.Text("Employee Name : $employeeName"),
  pw.Text("Employee ID : $employeeId"),

  pw.Text(
    "Date Range : "
    "${startDate.day}-${startDate.month}-${startDate.year}"
    " to "
    "${endDate.day}-${endDate.month}-${endDate.year}",
  ),

  pw.SizedBox(height: 10),
  pw.Divider(),

          ];

          for (final entry in grouped.entries) {
            widgets.add(pw.SizedBox(height: 15));

            widgets.add(
              pw.Text(
                "Month: ${entry.key}",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );

            widgets.add(
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  
                  'Punch In',
                  'Punch Out',
                  'Earned',
                  'Deduction',
                ],
                data: entry.value.map((r) {

  String getTime(dynamic value) {
  if (value == null) return '-';

  try {
    final dt = DateTime.parse(value.toString());

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? "PM" : "AM";

    final minute = dt.minute.toString().padLeft(2, '0');

    return "$hour:$minute $amPm";
  } catch (e) {
    return '-';
  }
}

  return [
    r['date'], // ✅ keep date column
    getTime(r['punch_in']), // ❌ remove date from time
    getTime(r['punch_out']),
    (r['earned_amount'] ?? 0).toDouble().toStringAsFixed(2),
    (r['deductions'] ?? 0).toDouble().toStringAsFixed(2),
  ];
}).toList(),
              ),
            );
          }

          return widgets;
        },
      ),
    );

 

try {
  final bytes = await pdf.save();

final dir = await getExternalStorageDirectory();

if (dir == null) {
  return;
}

final fileName =
    "salary_report_${employeeId}_${startDate.day}-${startDate.month}-${startDate.year}.pdf";

final file = File("${dir.path}/$fileName");

await file.writeAsBytes(bytes);

OpenFilex.open(file.path);

  /// SUCCESS MESSAGE
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Salary PDF downloaded successfully")),
  );

  /// OPEN FILE
  OpenFilex.open(file.path);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Salary PDF download failed")),
  );
}
  }
  Future<List<Map<String, dynamic>>> getAttendanceForPdf({
  required String userId,
  required DateTime start,
  required DateTime end,
  required dynamic supabase,
}) async {
  final response = await supabase
      .from('attendance')
      .select('date,status,earned_amount,deductions,punch_in,punch_out')
      .eq('user_id', userId)
      .gte('date',
          "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}")
      .lte('date',
          "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}")
      .order('date');

  return List<Map<String, dynamic>>.from(response);
}

}