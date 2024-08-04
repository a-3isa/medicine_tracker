import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'medicine.dart';

class PDFCreator {
  Future<pw.Font> loadFont() async {
    final fontData = await rootBundle.load('assets/arial.ttf');
    return pw.Font.ttf(fontData);
  }

  List getLastTenItems(List items) {
    if (items.length <= 10) {
      return items;
    }
    return items.sublist(items.length - 10, items.length);
  }

  Future<XFile> createPDF(
      BuildContext context,
      Future<List<Medicine>> medicinesFuture,
      Future<List<Biometrics>> biometricsFuture,
      Future<List<Bipap>> bipapFuture,
      Future<List<Personal>> personalsFuture,
      bool last10days) async {
    final pdf = pw.Document();
    final medicines = await medicinesFuture;
    final last10Days = last10days;
    // medicines = getLastTenItems(medicines);
    final biometrics = await biometricsFuture;
    final bipaps = await bipapFuture;

    final personals = await personalsFuture;

    final headerFont = await loadFont();
    final normalFont = await loadFont();

    pw.TextStyle headerStyle = pw.TextStyle(
      font: headerFont,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle personalStyle = pw.TextStyle(
      font: headerFont,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    pw.TextStyle normalStyle = pw.TextStyle(
      font: normalFont,
      fontSize: 8,
    );

    List<pw.Widget> content = [
      pw.Center(
        child: pw.Text(
          'Medicine Schedule \n',
          style: headerStyle,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        pw.Text(
          '${Languages.of(context)!.name}: ${personals[0].name}',
          style: personalStyle,
        ),
      ]),
      pw.Row(children: [
        pw.Text(
          '${Languages.of(context)!.age}: ${personals[0].age}',
          style: personalStyle,
        ),
      ]),
      pw.Row(children: [
        pw.Text(
            '${Languages.of(context)!.personalCase}: ${personals[0].personCase}',
            style: personalStyle),
      ]),
      pw.SizedBox(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child:
              pw.Container(), // Add a child widget inside the Padding if needed
        ),
      ),
      pw.Container(
        height: 2,
        width: double.infinity,
        color: PdfColors.black,
      ),
      pw.SizedBox(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child:
              pw.Container(), // Add a child widget inside the Padding if needed
        ),
      ),
    ];
    // pdf.addPage(
    //   pw.MultiPage(
    //     textDirection: Languages.of(context)!.direction,
    //     build: (pw.Context context) => content,
    //   ),
    // );

    final dayDateGroups = <DateTime, Map<String, List<Medicine>>>{};
    final dateGroups = <String, List<Biometrics>>{};
    final bipapGroups = <DateTime, List<Bipap>>{};

    for (var medicine in medicines) {
      List days = medicine.dates;
      if (last10Days) {
        days = getLastTenItems(medicine.dates);
      }
      // List last10days = getLastTenItems(medicine.dates);
      for (var dateMap in days) {
        dateMap.forEach((date, day) {
          // String formattedDate = DateFormat('MM-dd').format(date);
          if (!dayDateGroups.containsKey(date)) {
            dayDateGroups[date] = {};
          }
          if (!dayDateGroups[date]!.containsKey(day)) {
            dayDateGroups[date]![day] = [];
          }
          dayDateGroups[date]![day]!.add(medicine);
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

    for (var bipap in bipaps) {
      final date = bipap.measurementDate;
      if (!bipapGroups.containsKey(date)) {
        bipapGroups[date] = [];
      }
      bipapGroups[date]!.add(bipap);
    }

    dayDateGroups.keys.expand((date) {
      return dayDateGroups[date]!.keys.map((day) {
        final medicinesForDayAndDate = dayDateGroups[date]![day]!;
        final biometricsForDate =
            dateGroups[DateFormat('MM-dd').format(date)] ?? [];
        // final prevDay = date.subtract(Duration(days: 1));
        // print(date);
        final bipapForDate =
            bipapGroups[date] ?? [];
        List<DateTime> keys = bipapGroups.keys.toList();
        int currentIndex = keys.indexOf(date);
        // print(keys);
        // print(currentIndex);
        // print("&&&&&&&&&&&&&&&&&&&&&&");
        // print(bipapForDate);
        // print(bipapGroups);
        if (currentIndex > 0) {
          int previousIndex = currentIndex - 1;
          DateTime previousKey = keys[previousIndex];
          final previousBipapForDate = bipapGroups[previousKey];
          int differenceInDays = bipapForDate[0]
              .measurementDate
              .difference(previousBipapForDate![0].measurementDate)
              .inDays;

          // Do something with previousBipapForDate
          // print((previousBipapForDate.first.bipap!-bipapForDate[0].bipap!)/differenceInDays);
          // print(differenceInDays);
          bipapForDate[0].bipap = (bipapForDate[0].bipap!-previousBipapForDate.first.bipap!)/differenceInDays;
          print("ooooooooooooooooooooooooooooo");
          print(bipapForDate[0].bipap);
        } 
        List<pw.Widget> dayDateContent = [
          pw.Center(
              child: pw.Text(
                  'Day: $day - Date: ${DateFormat('MM-dd').format(date)}',
                  style: normalStyle,
                  textAlign: pw.TextAlign.center)),
          pw.SizedBox(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw
                  .Container(), // Add a child widget inside the Padding if needed
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Medicine Table
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Table(border: pw.TableBorder.all(), columnWidths: {
                      0: const pw.FixedColumnWidth(200),
                      1: const pw.FixedColumnWidth(200),
                    }, children: [
                      pw.TableRow(
                        children: [
                          pw.Center(
                            child: pw.Text('Home Bipap', style: normalStyle),
                          ),
                          pw.Center(
                            child: pw.Text('${bipapForDate.isNotEmpty? bipapForDate[0].bipap : 0}',
                                style: normalStyle),
                          ),
                        ],
                      ),
                    ]),
                    pw.Table(
                      columnWidths: {
                        0: const pw.FixedColumnWidth(200),
                        1: const pw.FixedColumnWidth(200),
                        2: const pw.FixedColumnWidth(200),
                        3: const pw.FixedColumnWidth(200),
                        4: const pw.FixedColumnWidth(200),
                        5: const pw.FixedColumnWidth(200),
                        6: const pw.FixedColumnWidth(200),
                        7: const pw.FixedColumnWidth(200),
                      },
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Center(
                              child:
                                  pw.Text('Medicine Name', style: normalStyle),
                            ),
                            pw.Center(
                              child: pw.Text('Time', style: normalStyle),
                            ),
                            // if (biometricsForDate.isNotEmpty) ...[
                            pw.Center(
                              child: pw.Text('Heart Rate', style: normalStyle),
                            ),

                            pw.Center(
                              child:
                                  pw.Text('Blood Pressure', style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text('Oxygen', style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text('Sugar', style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text('Time', style: normalStyle),
                            ),
                          ],
                          // ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.ListView.builder(
              itemCount:
                  max(medicinesForDayAndDate.length, biometricsForDate.length),
              itemBuilder: (context, index) {
                final medicine = index < medicinesForDayAndDate.length
                    ? medicinesForDayAndDate[index]
                    : null;
                final timeIndex = medicine?.dates
                    .indexWhere((dateMap) => dateMap.containsKey(date));

                final biometric = index < biometricsForDate.length
                    ? biometricsForDate[index]
                    : null;
                // double? bipap_value = index != biometricsForDate.length - 1
                //     ? (biometricsForDate[index].bipap ?? 0) -
                //         (biometricsForDate[index + 1].bipap ?? 0)
                //     : 0;

                return pw.Column(children: [
                  pw.Table(
                      columnWidths: {
                        0: const pw.FixedColumnWidth(200),
                        1: const pw.FixedColumnWidth(200),
                        2: const pw.FixedColumnWidth(200),
                        3: const pw.FixedColumnWidth(200),
                        4: const pw.FixedColumnWidth(200),
                        5: const pw.FixedColumnWidth(200),
                        6: const pw.FixedColumnWidth(200),
                        7: const pw.FixedColumnWidth(200),
                      },
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Center(
                              child: pw.Text(medicine?.name ?? "",
                                  style: normalStyle),
                            ),
                            pw.Center(
                              child: pw.Text(
                                  medicine?.checkboxStates[timeIndex!][medicine
                                          .checkboxStates[timeIndex!]
                                          .keys
                                          .first] ??
                                      "",
                                  style: normalStyle),
                            ),

                            // if (biometricsForDate.isNotEmpty &&
                            //     biometric != null) ...[
                            pw.Center(
                              child: pw.Text(
                                  biometric?.heartRate?.toString() ?? '',
                                  style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text(
                                  biometric?.bloodPressure != null
                                      ? '${biometric?.bloodPressure![0]}/${biometric?.bloodPressure![1]}'
                                      : '',
                                  style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text(
                                  biometric?.oxygen?.toString() ?? '',
                                  style: normalStyle),
                            ),

                            pw.Center(
                              child: pw.Text(biometric?.sugar?.toString() ?? '',
                                  style: normalStyle),
                            ),
                            // pw.Center(
                            //   child: pw.Text(bipap_value.toString(),
                            //       style: normalStyle),
                            // ),
                            pw.Center(
                              child: pw.Text(biometric?.time?.toString() ?? '',
                                  style: normalStyle),
                            ),
                          ],
                          // ],
                        )
                      ])
                ]);
              }),
          pw.SizedBox(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw
                  .Container(), // Add a child widget inside the Padding if needed
            ),
          ),
          pw.Container(
            height: 2,
            width: double.infinity,
            color: PdfColors.red,
          ),
          pw.SizedBox(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw
                  .Container(), // Add a child widget inside the Padding if needed
            ),
          ),
        ];
        content.addAll(dayDateContent);

        return dayDateContent;
      });
    }).toList();
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(10),
        textDirection: Languages.of(context)!.direction,
        build: (pw.Context context) => content,
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report.pdf');
    await file.writeAsBytes(await pdf.save());
    return XFile(file.path);
  }
}

void sharePdf(XFile pdfFile) async {
  Share.shareXFiles([pdfFile], text: 'Here is the PDF file of the medicines.');
}
