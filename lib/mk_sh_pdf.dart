import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'medicine.dart';

class PDFCreator {
  static Future<pw.Font> loadFont() async {
    final fontData = await rootBundle.load('assets/NotoSans-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<XFile> createPDF(Future<List<Medicine>> medicinesFuture,
      Future<List<Biometrics>> biometricsFuture) async {
    final pdf = pw.Document();
    final medicines = await medicinesFuture;
    final biometrics = await biometricsFuture;

    final headerFont = await loadFont();
    final normalFont = await loadFont();

    pw.TextStyle headerStyle = pw.TextStyle(
      font: headerFont,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle normalStyle = pw.TextStyle(
      font: normalFont,
      fontSize: 10,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Extract unique days and their corresponding dates
          final uniqueDays = <String>{};
          final uniqueDates = <String, String>{};

          for (var medicine in medicines) {
            for (var i = 0; i < medicine.days.length; i++) {
              uniqueDays.add(medicine.days[i]);
              uniqueDates[medicine.days[i]] = medicine.dates[i];
            }
          }

          // Parse the dates and associate them with days for sorting
          final dayDatePairs = uniqueDays.map((day) {
            final dateStr = uniqueDates[day];
            final date =
                dateStr != null ? DateFormat('MM-dd').parse(dateStr) : null;
            return {'day': day, 'date': date};
          }).toList();

          // Sort the pairs by date
          dayDatePairs.sort((a, b) {
            final dateA = a['date'] as DateTime?;
            final dateB = b['date'] as DateTime?;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });

          // Extract sorted days
          final sortedDays =
              dayDatePairs.map((pair) => pair['day'] as String).toList();

          return pw.Column(
            children: [
              pw.Text('Medicine Schedule', style: headerStyle),
              pw.SizedBox(height: 20),
              ...sortedDays.map((day) {
                final medicinesForDay = medicines
                    .where((medicine) => medicine.days.contains(day))
                    .toList();

                // Find all biometric data for the day
                final biometricsForDay = biometrics.where(
                  (biometric) => biometric.measurementDate == uniqueDates[day],
                ).toList();

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Day: $day ${uniqueDates[day]}',
                        style: normalStyle),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Medicine Table
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Table(
                                border: pw.TableBorder.all(),
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(5.0),
                                        child: pw.Center(
                                          child: pw.Text('Medicine Name',
                                              style: normalStyle),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(5.0),
                                        child: pw.Center(
                                          child: pw.Text('Time',
                                              style: normalStyle),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...medicinesForDay.map((medicine) {
                                    final timeIndex =
                                        medicine.days.indexOf(day);
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(medicine.name,
                                              style: normalStyle),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                              medicine.hours[timeIndex],
                                              style: normalStyle),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        // Biometrics Table
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Table(
                                columnWidths: {
          0: const pw.FixedColumnWidth(200), // Set the width of the first column (index 0)
          1: const pw.FixedColumnWidth(200), // Set the width of the first column (index 0)
          2: const pw.FixedColumnWidth(200), // Set the width of the first column (index 0)
          3: const pw.FixedColumnWidth(200), // Set the width of the first column (index 0)
          4: const pw.FixedColumnWidth(200), // Set the width of the first column (index 0)
          // Add more column widths if needed
        },
                                border: pw.TableBorder.all(),
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Center(
                                          child: pw.Text('Time',
                                              style: normalStyle),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Center(
                                          child: pw.Text('Heart Rate',
                                              style: normalStyle),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Center(
                                          child: pw.Text('Blood Pressure',
                                              style: normalStyle),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Center(
                                          child: pw.Text('Oxygen',
                                              style: normalStyle),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Center(
                                          child: pw.Text('Sugar',
                                              style: normalStyle),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...biometricsForDay.map((biometric) {
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                            biometric.time?.toString() ?? 'N/A',
                                            style: normalStyle,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                            biometric.heartRate?.toString() ??
                                                'N/A',
                                            style: normalStyle,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                            biometric.bloodPressure != null
                                                ? '${biometric.bloodPressure![0]}/${biometric.bloodPressure![1]}'
                                                : 'N/A',
                                            style: normalStyle,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                            biometric.oxygen?.toString() ??
                                                'N/A',
                                            style: normalStyle,
                                          ),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5.0),
                                          child: pw.Text(
                                            biometric.sugar?.toString() ??
                                                'N/A',
                                            style: normalStyle,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report.pdf');
    await file.writeAsBytes(await pdf.save());
    return XFile(file.path);
  }

}

void sharePdf(XFile pdfFile) async {
  print(pdfFile.path);
  Share.shareXFiles([pdfFile], text: 'Here is the PDF file of the medicines.');
}
