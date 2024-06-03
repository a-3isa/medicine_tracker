import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'language.dart';

class LanguageEn extends Languages {
  @override
  String get currentDayName => DateFormat('EEEE', ).format(DateTime.now());

  @override
  String get currentDate => DateFormat('MM/dd' ).format(DateTime.now());

  @override
  String get selectLanguage => "Select your language";

  @override
  String get timeColumn => "Time";
  
  @override
  String get imageColumn => 'Image';
  
  @override
  String get medicineColumn => 'Medicine';
  
  @override
  List<String> get timeOptions => ['Before\nbreakfast', 'After\nbreakfast', 'Before\ndinner', 'After\ndinner', 'Before\nlaunch', 'After\nlaunch'];
  
  @override
  String get add =>'Add';
  
  @override
  String get addMedicine => 'Add Medicine';
  
  @override
  String get cancel => 'Cancel';
  
  @override
  String get enterMedicineName => 'Enter medicine name';
  
  @override
  String get selectImage => 'Select Image';
  
  @override
  String get delete => "Delete";
  
  @override
  String get editMedicine => 'Edit Medicine';
  
  @override
  String get noImageSelected => 'No Image Selected';
  
  @override
  String get save => "Save";
  
  @override
  String get confirmDelete => "Confirm Delete";
  
  @override
  String get deleteMessage => 'Are you sure you want to delete this medicine?';
  
  @override
  String get languageSelection => 'Language Selection';
  
  @override
  String get proceedToApp => 'Proceed to App';
  
  @override
  String get diastolicBloodPressure => 'Diastolic Blood Pressure';
  
  @override
  String get enterBiometrics => 'Enter Biometrics';
  
  @override
  String get heartRate => 'Heart Rate';
  
  @override
  String get oxygenLevel => 'Oxygen Level';
  
  @override
  String get sugarLevel => 'Sugar Level';
  
  @override
  String get systolicBloodPressure => 'Systolic Blood Pressure';
  
  @override
  String get age => "Age";
  
  @override
  String get name => "Name";
  
  @override
  String get personalCase => "Case";
  
  @override
  // TODO: implement inputBiometrics
  String get inputBiometrics => "Input Biometrics";
  
  @override
  // TODO: implement menu
  String get menu => "Menu";
  
  @override
  // TODO: implement sharePDF
  String get sharePDF => "Share";
  
  @override
  // TODO: implement addTime
  String get addTime => "Add time";
  String get editTime => "Edit time";
  String get stop => "Stop";
  
  @override
  // TODO: implement direction
  pw.TextDirection get direction => pw.TextDirection.ltr;
}