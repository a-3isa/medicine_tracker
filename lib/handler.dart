import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medicine_tracker/classes_handler.dart';
import 'package:medicine_tracker/edit_alarm.dart';
import 'package:medicine_tracker/home_screen.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:medicine_tracker/medicine.dart';
import 'package:medicine_tracker/mk_sh_pdf.dart';
import 'package:medicine_tracker/ring.dart';
import 'dart:async';

class MedicineTablePage extends StatefulWidget {
  const MedicineTablePage({super.key});

  @override
  _MedicineTablePageState createState() => _MedicineTablePageState();
}

class _MedicineTablePageState extends State<MedicineTablePage> {
  List<Medicine>? medicines;
  List<Biometrics>? biometricss;
  static StreamSubscription<AlarmSettings>? subscription;
  late List<AlarmSettings> alarms;
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
    loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            ExampleAlarmRingScreen(alarmSettings: alarmSettings),
      ),
    );
    loadAlarms();
  }

  Future<int?> navigateToAlarmScreen(AlarmSettings? settings,String medicineName) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: ExampleAlarmEditScreen(alarmSettings: settings,medicineName:medicineName),
        );
      },
    );

    if (res != null && res['success'] == true) {
      loadAlarms();
      final alarmId = res['alarmId'];
      return alarmId;
    } else {
      return null;
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Medicine Tracker'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  Languages.of(context)!.menu,
                  style: const TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(Languages.of(context)!.sharePDF),
                onTap: () async {
                  final pdfFile = await PDFCreator.createPDF(
                      loadMedicines(), loadBiometrics(), loadPersonal());
                  sharePdf(pdfFile);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(Languages.of(context)!.inputBiometrics),
                onTap: () {
                  _showBiometricsInputPopup(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box_rounded),
                title: Text(Languages.of(context)!.addMedicine),
                onTap: () {
                  _showAddMedicineDialog(context);
                },
              ),
            ],
          ),
        ),
        body: medicines != null
            ? MedicineTable(
                medicines: medicines!,
                // onCheckboxChanged: onCheckboxChanged,
                onDeletePressed: _deleteMedicine,
                onEditPressed: _showEditMedicineDialog,
              )
            : const Text(""));
  }

  void onMedicineAdded(String medicineName, String? imagePath, String time,int? alarmId) {
    setState(() {
      List<Map<bool, String>> initialCheckboxStates =
          List.filled(7, {false: ""});
      // List<String> initialhours = List.filled(7, "");
      final creationDay = DateTime.now();
      // List<String> days = [];
      List<Map<String, String>> dates = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = creationDay.add(Duration(days: i));
        String dayName = DateFormat(
          'EEEE',
        ).format(date);
        // days.add(dayName);
        dates.add({
          DateFormat(
            'MM-dd',
          ).format(date): dayName
        });
      }

      final medicine = Medicine(
        name: medicineName,
        imagePath: imagePath,
        time: time,
        creationDay: creationDay,
        alarmId:alarmId ,
        // days: days,
        dates: dates, checkboxStates: initialCheckboxStates,
        // checkboxStates: initialCheckboxStates,
        // hours: initialhours,
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
      if (medicine.alarmId != null) Alarm.stop(medicine.alarmId!);
      
      medicines!.remove(medicine);
      saveMedicines(medicines!);
      // Navigator.of(context).pop();
      // Navigator.of(context).pop();
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
      saveMedicines(medicines!);
      // Navigator.of(context).pop();
    });
  }

  int _getTimeIndex(String time) {
    final timeOptions = Languages.of(context)!.timeOptions;
    return timeOptions.indexOf(time);
  }

  // void onCheckboxChanged(int medicineIndex, int dayIndex, bool value,String time) {
  //   setState(() {
  //     if (medicines != null) {
  //       medicines![medicineIndex].checkboxStates[dayIndex].keys.first = value;
  //       saveMedicines(medicines!);
  //     }
  //   });
  // }

  Future<void> _showAddMedicineDialog(BuildContext context) async {
    final TextEditingController textEditingController = TextEditingController();
    bool isChecked = false;
    int? alarmId;

    File? selectedImage;
    String time =
        Languages.of(context)!.timeOptions[0]; // Default selected time
    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Languages.of(context)!.addMedicine),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: Languages.of(context)!.enterMedicineName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 30),
                  DropdownButton<String>(
                    isExpanded: true,
                    itemHeight: 70,
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
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(value),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: isChecked,
                    title: Text(Languages.of(context)!.addTime),
                    onChanged: (bool? value) {
                      setState(() {
                        isChecked = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  isChecked && textEditingController.text.trim().isNotEmpty
                      ? ElevatedButton(
                          onPressed: () async {
                            final String medicineName = textEditingController.text.trim();
                            alarmId = await navigateToAlarmScreen(null,medicineName);
                          },
                          child: const Icon(Icons.alarm_add_rounded, size: 33),
                        )
                      : Text(""),
                ],
              ),
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
                    onMedicineAdded(medicineName, selectedImage?.path, time,alarmId);
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
            title: Text(
              Languages.of(context)!.editMedicine,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: Languages.of(context)!.enterMedicineName,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  selectedImage != null
                      ? Image.file(
                          selectedImage!,
                          height: 100,
                        )
                      : Text(Languages.of(context)!.noImageSelected),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
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
                    icon: const Icon(Icons.image),
                    label: Text(Languages.of(context)!.selectImage),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTime = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
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
            ),
            actions: [
              TextButton(
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
                              Navigator.of(context)
                                  .pop(); // Close the confirmation dialog
                              Navigator.of(context)
                                  .pop(); // Close the edit dialog
                            },
                            child: Text(Languages.of(context)!.delete),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text(
                  Languages.of(context)!.delete,
                  style: const TextStyle(color: Colors.red),
                ),
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
          title: Text(
            Languages.of(context)!.enterBiometrics,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.heartRate,
                      prefixIcon: const Icon(Icons.favorite),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      heartRate = int.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.systolicBloodPressure,
                      prefixIcon: const Icon(Icons.bloodtype),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      bloodPressure[0] = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.diastolicBloodPressure,
                      prefixIcon: const Icon(Icons.bloodtype),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      bloodPressure[1] = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.oxygenLevel,
                      // prefixIcon: Icon(Icons.),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      oxygen = double.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.sugarLevel,
                      // prefixIcon: Icon(Icons.suger),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      sugar = double.tryParse(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.cancel),
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
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.save),
            ),
          ],
        );
      },
    );
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
