import 'dart:convert';
import 'dart:io';
import 'package:medicine_tracker/models/medicine.dart';
import 'package:path_provider/path_provider.dart';



// Future<void> savePersonal(List<Personal> personals) async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/personal.json');
//   final List<dynamic> jsonList =
//       personals.map((personal) => personal.toJson()).toList();
//   final jsonString = json.encode(jsonList);
//   await file.writeAsString(jsonString);
// }

// Future<void> saveBipap(List<Bipap> bipaps) async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/bipap.json');
//   final List<dynamic> jsonList =
//       bipaps.map((bipap) => bipap.toJson()).toList();
//   final jsonString = json.encode(jsonList);
//   await file.writeAsString(jsonString);
// }

// Future<List<Bipap>> loadBipap() async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/bipap.json');
//   if (file.existsSync()) {
//     final jsonString = file.readAsStringSync();
//     final List<dynamic> jsonList = json.decode(jsonString);
//     final data = jsonList.map((json) => Bipap.fromJson(json)).toList();
//     return data;
//   }
//   return [];
// }

// Future<void> saveMedicines(List<Medicine> medicines) async {
//     final Directory appDocumentsDirectory =
//         await getApplicationDocumentsDirectory();
//     final File file = File('${appDocumentsDirectory.path}/medicines.json');
//     // print(medicines);
//     final List<dynamic> jsonList =
//         medicines.map((medicine) => medicine.toJson()).toList();
//     final jsonString = json.encode(jsonList);
//     await file.writeAsString(jsonString);
//   }

// Future<List<Personal>> loadPersonal() async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/personal.json');
//   if (file.existsSync()) {
//     final jsonString = file.readAsStringSync();
//     final List<dynamic> jsonList = json.decode(jsonString);
//     final data = jsonList.map((json) => Personal.fromJson(json)).toList();
//     return data;
//   }
//   return [];
// }



// Future<List<Medicine>> loadMedicines() async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/medicines.json');
//   if (file.existsSync()) {
//     final jsonString = file.readAsStringSync();
//     final List<dynamic> jsonList = json.decode(jsonString);
//     final data = jsonList.map((json) => Medicine.fromJson(json)).toList();
//     return data;
//   }
//   return [];
// }

// Future<void> saveBiometrics(List<Biometrics> biometricsList) async {
//     final Directory appDocumentsDirectory =
//         await getApplicationDocumentsDirectory();
//     final File file = File('${appDocumentsDirectory.path}/biometrics.json');
//     final List<dynamic> jsonList =
//         biometricsList.map((biometrics) => biometrics.toJson()).toList();
//     final jsonString = json.encode(jsonList);
//     await file.writeAsString(jsonString);
//   }

// Future<List<Biometrics>> loadBiometrics() async {
//   final Directory appDocumentsDirectory =
//       await getApplicationDocumentsDirectory();
//   final File file = File('${appDocumentsDirectory.path}/biometrics.json');
//   if (file.existsSync()) {
//     final jsonString = file.readAsStringSync();
//     final List<dynamic> jsonList = json.decode(jsonString);
//     final data = jsonList.map((json) => Biometrics.fromJson(json)).toList();
//     return data;
//   }
//   return [];
// }


Future<void> saveData<T>(List<T> dataList, String fileName, Map<String, dynamic> Function(T) toJson) async {
  final Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/$fileName.json');
  final List<dynamic> jsonList = dataList.map((data) => toJson(data)).toList();
  final jsonString = json.encode(jsonList);
  await file.writeAsString(jsonString);
}

// Generic load function
Future<List<T>> loadData<T>(String fileName, T Function(Map<String, dynamic>) fromJson) async {
  final Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
  final File file = File('${appDocumentsDirectory.path}/$fileName.json');
  if (file.existsSync()) {
    final jsonString = file.readAsStringSync();
    final List<dynamic> jsonList = json.decode(jsonString);
    final dataList = jsonList.map((json) => fromJson(json)).toList();
    return dataList;
  }
  return [];
}


// Specific save functions
Future<void> savePersonal(List<Personal> personals) async {
  await saveData(personals, 'personal', (personal) => personal.toJson());
}

Future<void> saveBipap(List<Bipap> bipaps) async {
  await saveData(bipaps, 'bipap', (bipap) => bipap.toJson());
}

Future<void> saveMedicines(List<Medicine> medicines) async {
  await saveData(medicines, 'medicines', (medicine) => medicine.toJson());
}

Future<void> saveBiometrics(List<Biometrics> biometricsList) async {
  await saveData(biometricsList, 'biometrics', (biometrics) => biometrics.toJson());
}

// Specific load functions
Future<List<Personal>> loadPersonal() async {
  return await loadData('personal', (json) => Personal.fromJson(json));
}

Future<List<Bipap>> loadBipap() async {
  return await loadData('bipap', (json) => Bipap.fromJson(json));
}

Future<List<Medicine>> loadMedicines() async {
  return await loadData('medicines', (json) => Medicine.fromJson(json));
}

Future<List<Biometrics>> loadBiometrics() async {
  return await loadData('biometrics', (json) => Biometrics.fromJson(json));
}