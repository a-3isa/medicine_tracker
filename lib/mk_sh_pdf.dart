import 'dart:io';

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

  static Future<XFile> createPDF(
      Future<List<Medicine>> medicinesFuture,
      Future<List<Biometrics>> biometricsFuture,
      Future<List<Personal>> personalsFuture) async {
    final pdf = pw.Document();
    final medicines = await medicinesFuture;
    final biometrics = await biometricsFuture;
    final personals = await personalsFuture;

    final headerFont = await loadFont();
    final normalFont = await loadFont();

    pw.TextStyle headerStyle = pw.TextStyle(
      font: headerFont,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle personalStyle = pw.TextStyle(
      font: headerFont,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle normalStyle = pw.TextStyle(
      font: normalFont,
      fontSize: 10,
    );

    void addContentToPage(pw.Document pdf, List<pw.Widget> content) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(children: content);
          },
        ),
      );
    }

    List<pw.Widget> content = [
      pw.Text('Medicine Schedule \n', style: headerStyle),
      pw.SizedBox(height: 20),
      pw.Row(children: [
        pw.Text(
          'Name: ${personals[0].name}',
          style: personalStyle,
        ),
      ]),
      pw.Row(children: [
        pw.Text('Age: ${personals[0].age}', style: personalStyle),
      ]),
      pw.Row(children: [
        pw.Text('Case: ${personals[0].personCase}', style: personalStyle),
      ]),
      pw.Text(
        "------------------------------------------------------------------------------------------------------------------- \n \n",
        style: personalStyle,
      ),
    ];

    final dayDateGroups = <String, Map<String, List<Medicine>>>{};
    final dateGroups = <String, List<Biometrics>>{};

    for (var medicine in medicines) {
      for (var dateMap in medicine.dates) {
        dateMap.forEach((day, date) {
          if (!dayDateGroups.containsKey(day)) {
            dayDateGroups[day] = {};
          }
          if (!dayDateGroups[day]!.containsKey(date)) {
            dayDateGroups[day]![date] = [];
          }
          dayDateGroups[day]![date]!.add(medicine);
        });
      }
    }

    for (var biometric in biometrics) {
      final date = biometric.measurementDate;
      if (!dateGroups.containsKey(date)) {
        dateGroups[date] = [];
      }
      dateGroups[date]!.add(biometric);
    }
    // print(dayDateGroups.keys);

    dayDateGroups.keys.expand((day) {
      return dayDateGroups[day]!.keys.map((date) {
        // print(day);
        // print(date);
        final medicinesForDayAndDate = dayDateGroups[day]![date]!;
        final biometricsForDate = dateGroups[day] ?? [];
        // print(biometricsForDate);
        // print(dateGroups);

        List<pw.Widget> dayDateContent = [
          pw.Text('Day: $day - Date: $date', style: normalStyle),
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
                                child: pw.Text('Medicine Name', style: normalStyle),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5.0),
                              child: pw.Center(
                                child: pw.Text('Time', style: normalStyle),
                              ),
                            ),
                          ],
                        ),
                        ...medicinesForDayAndDate.map((medicine) {
                          // print(medicine.dates);
                          final timeIndex = medicine.dates.indexWhere((dateMap) => dateMap.containsKey(day));
                          // print(timeIndex);
                          // print(medicine.checkboxStates[timeIndex]);
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(medicine.name, style: normalStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                    medicine.checkboxStates[timeIndex][medicine.checkboxStates[timeIndex].keys.first] ?? "",
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
                        0: const pw.FixedColumnWidth(200),
                        1: const pw.FixedColumnWidth(200),
                        2: const pw.FixedColumnWidth(200),
                        3: const pw.FixedColumnWidth(200),
                        4: const pw.FixedColumnWidth(200),
                      },
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text('Time', style: normalStyle),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text('Heart Rate', style: normalStyle),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text('Blood Pressure', style: normalStyle),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text('Oxygen', style: normalStyle),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text('Sugar', style: normalStyle),
                              ),
                            ),
                          ],
                        ),
                        ...biometricsForDate.map((biometric) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  biometric.time?.toString() ?? 'N/A',
                                  style: normalStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  biometric.heartRate?.toString() ?? 'N/A',
                                  style: normalStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  biometric.bloodPressure != null
                                      ? '${biometric.bloodPressure![0]}/${biometric.bloodPressure![1]}'
                                      : 'N/A',
                                  style: normalStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  biometric.oxygen?.toString() ?? 'N/A',
                                  style: normalStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  biometric.sugar?.toString() ?? 'N/A',
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
            ],
          ),
          pw.SizedBox(height: 20),
        ];

        if (content.length + dayDateContent.length > 25) { // Adjust this value based on your page size
          addContentToPage(pdf, content);
          content = [];
        }
        content.addAll(dayDateContent);
        return dayDateContent;
      });
    }).toList();

    if (content.isNotEmpty) {
      addContentToPage(pdf, content);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report.pdf');
    await file.writeAsBytes(await pdf.save());
    return XFile(file.path);
  }
}

void sharePdf(XFile pdfFile) async {
  Share.shareXFiles([pdfFile], text: 'Here is the PDF file of the medicines.');
}
