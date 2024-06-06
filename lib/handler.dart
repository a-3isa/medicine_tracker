import 'dart:io';
import 'dart:typed_data';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medicine_tracker/classes_handler.dart';
// import 'package:medicine_tracker/edit_alarm.dart';
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
  bool loading = false;

  static StreamSubscription<AlarmSettings>? subscription;
  late List<AlarmSettings> alarms;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late String assetAudio;
  late String notificationBody;
  @override
  void initState() {
    super.initState();

    loopAudio = true;
    vibrate = true;
    volume = null;
    assetAudio = 'assets/marimba.mp3';

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
                  final pdfFile = await PDFCreator.createPDF(context,
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
              ListTile(
                leading: const Icon(Icons.account_circle_rounded),
                title: Text(Languages.of(context)!.editProfile),
                onTap: () {
                  _showEditPersonalDialog(context);
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

  (AlarmSettings, int, DateTime) buildAlarmSettings(String medicineName) {
    final id = DateTime.now().millisecondsSinceEpoch % 10000 + 1;
    // selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    // selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume,
      assetAudioPath: assetAudio,
      notificationTitle: 'Medicine Time',
      notificationBody: 'It is time to take your $medicineName.',
      enableNotificationOnKill: Platform.isIOS,
    );
    return (alarmSettings, id, selectedDateTime);
  }

  Future<(int, DateTime)> saveAlarm(String medicineName) async {
    final (settings, id, selectedDateTime) = buildAlarmSettings(medicineName);
    await Alarm.set(alarmSettings: settings);
    return (id, selectedDateTime);
  }

  void onMedicineAdded(String medicineName, Uint8List? image, String period,
      int? alarmId, DateTime time) {
    setState(() {
      List<Map<bool, String>> initialCheckboxStates =
          List.filled(1, {false: ""});
      // List<String> initialhours = List.filled(7, "");
      DateTime creationDay = DateTime.now();
      creationDay =
          DateTime(creationDay.year, creationDay.month, creationDay.day);
      // List<String> days = [];
      List<Map<DateTime, String>> dates = [];

      // for (int i = 0; i < 7; i++) {
      // DateTime date = creationDay.add(Duration(days: 0));
      String dayName = DateFormat(
        'EEEE',
      ).format(creationDay);
      // days.add(dayName);
      dates.add({creationDay: dayName});
      // }

      final medicine = Medicine(
        time: time,
        name: medicineName,
        image: image,
        period: period,
        // creationDay: creationDay,
        alarmId: alarmId,
        // days: days,
        dates: dates, checkboxStates: initialCheckboxStates,
        // checkboxStates: initialCheckboxStates,
        // hours: initialhours,
      );
      if (medicines != null) {
        medicines!.add(medicine);
        medicines!.sort((a, b) {
          if (a.time.hour == b.time.hour) {
            return a.time.minute.compareTo(b.time.minute);
          }
          return a.time.hour.compareTo(b.time.hour);
        });
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
      String selectedPeriod, Uint8List? imageBytes, DateTime selectedTime) {
    setState(() {
      medicine.name = updatedMedicineName;
      medicine.period = selectedPeriod;
      if (medicine.time != selectedTime) {
        medicine.time = selectedTime;
        Alarm.stop(medicine.alarmId!).then((bool result) {
          final editedAlarmSettings = AlarmSettings(
            id: medicine.alarmId!,
            dateTime: selectedDateTime,
            loopAudio: loopAudio,
            vibrate: vibrate,
            volume: volume,
            assetAudioPath: assetAudio,
            notificationTitle: 'Medicine Time',
            notificationBody: 'It is time to take your ${medicine.name}.',
            enableNotificationOnKill: Platform.isIOS,
          );
          return Alarm.set(alarmSettings: editedAlarmSettings);
        });
      }

      if (imageBytes != null) {
        medicine.image = imageBytes;
      }
      medicines!.sort((a, b) {
        if (a.time.hour == b.time.hour) {
          return a.time.minute.compareTo(b.time.minute);
        }
        return a.time.hour.compareTo(b.time.hour);
      });
      saveMedicines(medicines!);
      // Navigator.of(context).pop();
    });
  }

  Future<void> pickTime(BuildContext context) async {
    final res = await showTimePicker(
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      context: context,
    );
    if (res != null) {
      setState(() {
        final now = DateTime.now();
        selectedDateTime = now.copyWith(
          hour: res.hour,
          minute: res.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _showAddMedicineDialog(BuildContext context) async {
    final TextEditingController textEditingController = TextEditingController();
    // bool isChecked = false;
    int? alarmId;
    selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);

    File? selectedImage;
    Uint8List? imageBytes ;
    String period =
        Languages.of(context)!.timeOptions[0]; // Default selected time
    late DateTime time;
    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Languages.of(context)!.addMedicine ,style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        setState(() async {
                          selectedImage = File(pickedFile.path);
                          imageBytes = await selectedImage!.readAsBytes();
                        });
                      }
                    },
                    child: Text(Languages.of(context)!.selectImage),
                  ),
                  const SizedBox(height: 30),
                  DropdownButton<String>(
                    isExpanded: true,
                    itemHeight: 70,
                    value: period,
                    onChanged: (String? newValue) {
                      setState(() {
                        period = newValue!;
                      });
                    },
                    items: Languages.of(context)!
                        .timeOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => pickTime(context),
                    // fillColor: Colors.black,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      child: Text(
                        Languages.of(context)!.addTime,
                      ),
                    ),
                  ),
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
                onPressed: () async {
                  final String medicineName = textEditingController.text.trim();
                  if (medicineName.isNotEmpty) {
                    (alarmId, time) = await saveAlarm(medicineName);
                    // print(time);

                    textEditingController.clear();
                    onMedicineAdded(medicineName, imageBytes, period,
                        alarmId, time);
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
    String selectedPeriod = medicine.period;
    selectedDateTime = medicine.time;

    File? selectedImage;
    Uint8List? image;
    if (medicine.image != null) {
      image = medicine.image!;
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
                        setState(() async {
                          selectedImage = File(pickedFile.path);
                          image = await selectedImage!.readAsBytes();
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
                    value: selectedPeriod,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPeriod = newValue!;
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
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => pickTime(context),
                        // fillColor: Colors.black,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: Text(
                            Languages.of(context)!.editTime,
                          ),
                        ),
                      ),
                      Checkbox(
                          value: medicine.checkboxStates.last.keys.first,
                          onChanged: (value) {
                            setState(() {
                              // print("************");
                              Map<bool, String> mapAtIndex =
                                  Map.from(medicine.checkboxStates.last);
                              mapAtIndex.remove(mapAtIndex.keys.first);
                              mapAtIndex[value!] = value == true
                                  ? DateFormat('hh:mm a').format(DateTime.now())
                                  : "";
                              medicine.checkboxStates.last = mapAtIndex;
                              saveMedicines(medicines!);
                            });
                          }),
                    ],
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
                    onEditMedicine(medicine, updatedMedicineName,
                        selectedPeriod, image, selectedDateTime);
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

  Future<void> _showEditPersonalDialog(BuildContext context) async {
    List<Personal>? personals = [];
    String name = "";
    String personCase = "";
    String age = "";

    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            Languages.of(context)!.editProfile,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.name,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.age,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      age = value;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: Languages.of(context)!.personalCase,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    onChanged: (value) {
                      personCase = value;
                    },
                  ),
                  const SizedBox(height: 32.0),
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
                Personal personal = Personal(
                  name: name,
                  age: age,
                  personCase: personCase,
                );
                personals[0] = personal;

                // personals.add(personal);
                await savePersonal(personals);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicineTablePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18.0),
              ),
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
