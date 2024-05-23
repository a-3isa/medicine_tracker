import 'dart:convert';
import 'dart:io';

import 'package:medicine_tracker/medicine.dart';
import 'package:path_provider/path_provider.dart';



Future<void> savePersonal(List<Personal> personals) async {
  final Directory appDocumentsDirectory =
      await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/personal.json');
  final List<dynamic> jsonList =
      personals.map((personal) => personal.toJson()).toList();
  final jsonString = json.encode(jsonList);
  await file.writeAsString(jsonString);
}

Future<void> saveMedicines(List<Medicine> medicines) async {
    final Directory appDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final File file = File('${appDocumentsDirectory.path}/medicines.json');
    // print(medicines);
    final List<dynamic> jsonList =
        medicines.map((medicine) => medicine.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

Future<List<Personal>> loadPersonal() async {
  final Directory appDocumentsDirectory =
      await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/personal.json');
  if (file.existsSync()) {
    final jsonString = file.readAsStringSync();
    final List<dynamic> jsonList = json.decode(jsonString);
    final data = jsonList.map((json) => Personal.fromJson(json)).toList();
    return data;
  }
  return [];
}

Future<List<Medicine>> loadMedicines() async {
  final Directory appDocumentsDirectory =
      await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/medicines.json');
  if (file.existsSync()) {
    final jsonString = file.readAsStringSync();
    final List<dynamic> jsonList = json.decode(jsonString);
    final data = jsonList.map((json) => Medicine.fromJson(json)).toList();
    return data;
  }
  return [];
}

Future<void> saveBiometrics(List<Biometrics> biometricsList) async {
    final Directory appDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final File file = File('${appDocumentsDirectory.path}/biometrics.json');
    final List<dynamic> jsonList =
        biometricsList.map((biometrics) => biometrics.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

Future<List<Biometrics>> loadBiometrics() async {
  final Directory appDocumentsDirectory =
      await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/biometrics.json');
  if (file.existsSync()) {
    final jsonString = file.readAsStringSync();
    final List<dynamic> jsonList = json.decode(jsonString);
    final data = jsonList.map((json) => Biometrics.fromJson(json)).toList();
    return data;
  }
  return [];
}
