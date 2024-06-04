import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

import 'medicine.dart';

class ExcelCreator {
  static Future<File> createExcel(
      BuildContext context,
      Future<List<Medicine>> medicinesFuture,
      Future<List<Biometrics>> biometricsFuture,
      Future<List<Personal>> personalsFuture) async {
    final medicines = await medicinesFuture;
    final biometrics = await biometricsFuture;
    final personals = await personalsFuture;

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add title and personal information
    sheet.appendRow(['Medicine Schedule Report']);
    sheet.appendRow(['']);
    sheet.appendRow(['Name', 'Age', 'Personal Case']);
    sheet.appendRow([personals[0].name, personals[0].age, personals[0].personCase]);
    sheet.appendRow(['']);

    // Add medicine schedule
    sheet.appendRow(['Medicine Name', 'Time']);
    for (var medicine in medicines) {
      for (var dateMap in medicine.dates) {
        dateMap.forEach((date, day) {
          final timeIndex = medicine.dates.indexWhere((dateMap) => dateMap.containsKey(date));
          sheet.appendRow([
            medicine.name,
            medicine.checkboxStates[timeIndex][medicine.checkboxStates[timeIndex].keys.first] ?? '',
          ]);
        });
      }
    }

    // Add biometric information
    sheet.appendRow(['']);
    sheet.appendRow(['Heart Rate', 'Blood Pressure', 'Oxygen', 'Sugar']);
    for (var biometric in biometrics) {
      sheet.appendRow([
        biometric.heartRate?.toString() ?? 'N/A',
        biometric.bloodPressure != null
            ? '${biometric.bloodPressure![0]}/${biometric.bloodPressure![1]}'
            : 'N/A',
        biometric.oxygen?.toString() ?? 'N/A',
        biometric.sugar?.toString() ?? 'N/A',
      ]);
    }

    // Save the file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/MedicineScheduleReport.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file;
  }
}
