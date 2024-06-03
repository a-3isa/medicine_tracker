import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;


import 'language.dart';

class LanguageAr extends Languages {
  @override
  String get currentDayName => DateFormat('EEEE','ar' ).format(DateTime.now());

  @override
  String get currentDate => DateFormat('MM/dd','ar' ).format(DateTime.now());

  @override
  String get selectLanguage => "اختر لغتك";

  @override
  String get timeColumn =>'الوقت';
  
  @override
  String get imageColumn => 'الصورة';
  
  @override
  String get medicineColumn => "الدواء";
  
  @override
  List<String> get timeOptions => ['قبل\nالفطار','بعد\nالفطار','قبل\nالغذاء','بعد\nالغذاء','قبل\nالعشاء','بعد\nالعشاء'];
  
  @override
  String get add => 'إضافة';
  
  @override
  String get addMedicine => "أضف دواء";
  
  @override
  String get cancel => "إلغاء";
  
  @override
  String get enterMedicineName => "أدخل اسم الدواء";
  
  @override
  String get selectImage => "اختر صورة";
  
  @override
  String get delete => "حذف";
  
  @override
  String get editMedicine => "تعديل دواء";
  
  @override
  String get noImageSelected => "لا توجد صورة";
  
  @override
  String get save => "حفظ";
  
  @override
  String get confirmDelete => 'تأكيد المسح';
  
  @override
  String get deleteMessage => "هل أنت متأكد أنك تريد حذف هذا الدواء؟";
  
  @override
  String get languageSelection => "اختيار اللغة";
  
  @override
  String get proceedToApp => 'أبدأ البرنامج';
  
  @override
  String get diastolicBloodPressure =>'ضغط الدم الانبساطي';
  
  @override
  String get enterBiometrics =>"أدخل القياسات الحيوية";
  
  @override
  String get heartRate => "معدل ضربات القلب";
  
  @override
  String get oxygenLevel => "مستوى الأكسجين";
  
  @override
  String get sugarLevel => "مستوى السكر";
  
  @override
  String get systolicBloodPressure => 'ضغط دم انقباضي';
  
  @override
  String get age => "العمر";
  
  @override
  String get name => "الإسم";
  
  @override
  String get personalCase => "الحالة";
  
  @override
  // TODO: implement inputBiometrics
  String get inputBiometrics => "أضف القياسات الحيوية";
  
  @override
  // TODO: implement menu
  String get menu => "القائمة";
  
  @override
  // TODO: implement sharePDF
  String get sharePDF => "مشاركة";
  
  @override
  // TODO: implement addTime
  String get addTime => "إضافة وقت";
  String get editTime => "تعديل وقت";
  String get stop => "إيقاف";

  @override
  pw.TextDirection get direction => pw.TextDirection.rtl;

}