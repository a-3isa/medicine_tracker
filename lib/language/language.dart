import 'package:flutter/material.dart';

abstract class Languages {
  static Languages? of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages);
  }

  String get currentDayName;

  String get currentDate;

  String get timeColumn;

  String get imageColumn;

  String get medicineColumn;

  String get selectLanguage;

  List<String> get timeOptions;
  String get addMedicine;
  String get enterMedicineName;
  String get selectImage;
  String get cancel;
  String get add;

  String get editMedicine;
  String get noImageSelected;
  String get delete;
  String get save;
  String get confirmDelete;
  String get deleteMessage;
  String get proceedToApp;
  String get languageSelection;
  String get oxygenLevel;
  String get diastolicBloodPressure;
  String get sugarLevel;
  String get systolicBloodPressure;
  String get heartRate;
  String get enterBiometrics;
  String get name;
  String get age;
  String get personalCase;
  String get inputBiometrics;
  String get sharePDF;
  String get menu;
}
