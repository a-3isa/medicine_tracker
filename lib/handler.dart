import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medicine_tracker/home_screen.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:medicine_tracker/medicine.dart';
import 'package:medicine_tracker/mk_sh_pdf.dart';
import 'package:path_provider/path_provider.dart';

class MedicineTablePage extends StatefulWidget {
  const MedicineTablePage({super.key});

  @override
  _MedicineTablePageState createState() => _MedicineTablePageState();
}

class _MedicineTablePageState extends State<MedicineTablePage> {
  List<Medicine>? medicines;
  List<Biometrics>? biometricss;

  @override
  void initState() {
    super.initState();
    medicines = [];
    biometricss = [];
    loadMedicines().then((loadedMedicines) {
      setState(() {
        medicines = loadedMedicines;
      });
    });
    loadBiometrics().then((loadedBiometrics) {
      setState(() {
        biometricss = loadedBiometrics;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Medicine Tracker'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdfFile =
                  await PDFCreator.createPDF(loadMedicines(), loadBiometrics());
              sharePdf(pdfFile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined),
            onPressed: () {
              _showBiometricsInputPopup(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              width: 850,
              child: Column(
                children: [
                  AddMedicineWidget(
                    onMedicineAdded: onMedicineAdded,
                  ),
                  const SizedBox(height: 20),
                  if (medicines != null)
                    MedicineTable(
                      medicines: medicines!,
                      onCheckboxChanged: onCheckboxChanged,
                      onDeletePressed: _deleteMedicine,
                      onEditPressed: _showEditMedicineDialog,
                      // onDaysEditPressed: _showBiometricsInputPopup,
                      // onBiometrics: _showBiometricsInputPopup,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMedicineDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void onMedicineAdded(String medicineName, String? imagePath, String time) {
    setState(() {
      final List<bool> initialCheckboxStates = List.filled(7, false);
      final List<String> initialhours = List.filled(7, "");
      final creationDay = DateTime.now();
      List<String> days = [];
      List<String> dates = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = creationDay.add(Duration(days: i));
        String dayName = DateFormat(
          'EEEE',
        ).format(date);
        days.add(dayName);
        dates.add(DateFormat(
          'MM-dd',
        ).format(date));
      }

      final medicine = Medicine(
        name: medicineName,
        imagePath: imagePath,
        time: time,
        creationDay: creationDay,
        days: days,
        dates: dates,
        checkboxStates: initialCheckboxStates,
        hours: initialhours,
      );
      if (medicines != null) {
        medicines!.add(medicine);
        medicines!.sort(
            (a, b) => _getTimeIndex(a.time).compareTo(_getTimeIndex(b.time)));
        saveMedicines(medicines!);
      }
    });
  }

  void onDeletePressed(Medicine medicine) {
    setState(() {
      medicines!.remove(medicine);
      saveMedicines(medicines!);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    });
  }

  void onEditMedicine(Medicine medicine, String updatedMedicineName,
      String selectedTime, String path, File? selectedImage) {
    setState(() {
      medicine.name = updatedMedicineName;
      medicine.time = selectedTime;
      if (selectedImage != null) {
        medicine.imagePath = selectedImage.path;
      }
      // Navigator.of(context).pop();
    });
  }

  int _getTimeIndex(String time) {
    final timeOptions = Languages.of(context)!.timeOptions;
    return timeOptions.indexOf(time);
  }

  void onCheckboxChanged(int medicineIndex, int dayIndex, bool value) {
    setState(() {
      if (medicines != null) {
        medicines![medicineIndex].checkboxStates[dayIndex] = value;
        saveMedicines(medicines!);
      }
    });
  }

  Future<void> _showAddMedicineDialog(BuildContext context) async {
    final TextEditingController textEditingController = TextEditingController();
    File? selectedImage;
    String time =
        Languages.of(context)!.timeOptions[0]; // Default selected time

    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Languages.of(context)!.addMedicine),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textEditingController,
                  decoration: InputDecoration(
                    hintText: Languages.of(context)!.enterMedicineName,
                  ),
                ),
                const SizedBox(height: 20),
                selectedImage != null
                    ? Image.file(
                        selectedImage!,
                        height: 100,
                      )
                    : const Text(""),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Text(Languages.of(context)!.selectImage),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: time,
                  onChanged: (String? newValue) {
                    setState(() {
                      time = newValue!;
                    });
                  },
                  items: Languages.of(context)!
                      .timeOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(Languages.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final String medicineName = textEditingController.text.trim();
                  if (medicineName.isNotEmpty) {
                    textEditingController.clear();
                    onMedicineAdded(medicineName, selectedImage?.path, time);
                    Navigator.of(context).pop();
                  }
                },
                child: Text(Languages.of(context)!.add),
              ),
            ],
          );
        },
      ),
    );
    textEditingController.clear();
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

  Future<void> saveMedicines(List<Medicine> medicines) async {
    final Directory appDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final File file = File('${appDocumentsDirectory.path}/medicines.json');
    final List<dynamic> jsonList =
        medicines.map((medicine) => medicine.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  Future<void> _showEditMedicineDialog(
      BuildContext context, Medicine medicine) async {
    final TextEditingController textEditingController = TextEditingController();
    textEditingController.text = medicine.name;
    String selectedTime = medicine.time;

    File? selectedImage;
    if (medicine.imagePath != null) {
      selectedImage = File(medicine.imagePath!);
    }

    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Languages.of(context)!.editMedicine),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textEditingController,
                  decoration: InputDecoration(
                    hintText: Languages.of(context)!.enterMedicineName,
                  ),
                ),
                const SizedBox(height: 20),
                selectedImage != null
                    ? Image.file(
                        selectedImage!,
                        height: 100,
                      )
                    : Text(Languages.of(context)!.noImageSelected),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Text(Languages.of(context)!.selectImage),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedTime,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTime = newValue!;
                    });
                  },
                  items: Languages.of(context)!
                      .timeOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(Languages.of(context)!.confirmDelete),
                        content: Text(Languages.of(context)!.deleteMessage),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(Languages.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                onDeletePressed(medicine);
                              });
                            },
                            child: Text(Languages.of(context)!.delete),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text(Languages.of(context)!.delete),
              ),
              ElevatedButton(
                onPressed: () {
                  final String updatedMedicineName =
                      textEditingController.text.trim();
                  if (updatedMedicineName.isNotEmpty) {
                    onEditMedicine(medicine, updatedMedicineName, selectedTime,
                        selectedImage!.path, selectedImage);
                    Navigator.of(context).pop();
                  }
                },
                child: Text(Languages.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBiometricsInputPopup(BuildContext context) async {
    String measurementDate = DateFormat('MM-dd').format(DateTime.now());
    String time = DateFormat('hh:mm').format(DateTime.now());
    int? heartRate;
    List<int>? bloodPressure = [0, 0];
    double? oxygen;
    double? sugar;

    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Text(Languages.of(context)!.enterBiometrics),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: Languages.of(context)!.heartRate),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    heartRate = int.tryParse(value);
                  },
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: Languages.of(context)!.systolicBloodPressure),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    bloodPressure[0] = int.tryParse(value) ?? 0;
                  },
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: Languages.of(context)!.diastolicBloodPressure),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    bloodPressure[1] = int.tryParse(value) ?? 0;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: Languages.of(context)!.oxygenLevel),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    oxygen = double.tryParse(value);
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: Languages.of(context)!.sugarLevel),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    sugar = double.tryParse(value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:  Text(Languages.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Biometrics biometrics = Biometrics(
                  measurementDate: measurementDate,
                  heartRate: heartRate,
                  bloodPressure: bloodPressure,
                  oxygen: oxygen,
                  sugar: sugar,
                  time: time,
                );
               
biometricss!.add(biometrics);

                await saveBiometrics(biometricss!);
                Navigator.of(context).pop();
              },
              child:  Text(Languages.of(context)!.save),
            ),
          ],
        );
      },
    );
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

  void _deleteMedicine(int index) {
    setState(() {
      if (medicines != null) {
        medicines!.removeAt(index);
        saveMedicines(medicines!);
      }
    });
    Navigator.of(context).pop();
  }
}

class AddMedicineWidget extends StatelessWidget {
  final void Function(String, String?, String) onMedicineAdded;

  const AddMedicineWidget({super.key, required this.onMedicineAdded});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 0);
  }
}
