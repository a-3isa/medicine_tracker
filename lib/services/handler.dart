/// Handler for medicine table page and related functionalities.
///
/// This widget manages the main screen of the medicine tracker app,
/// including displaying medicines, adding/editing/deleting medicines,
/// handling alarms, and providing access to other features like biometrics and PDF sharing.
class MedicineTablePage extends StatefulWidget {
  /// Creates a new MedicineTablePage instance.
  const MedicineTablePage({super.key});

  @override
  _MedicineTablePageState createState() => _MedicineTablePageState();
}

class _MedicineTablePageState extends State<MedicineTablePage> {
  /// List of medicines loaded from storage.
  List<Medicine>? medicines;

  /// List of biometrics data loaded from storage.
  List<Biometrics>? biometricss;

  /// List of bipap data loaded from storage.
  List<Bipap>? bipaps;

  /// Indicates if data is currently loading.
  bool loading = false;

  /// Subscription for alarm ring stream.
  static StreamSubscription<AlarmSettings>? subscription;

  /// List of active alarms.
  late List<AlarmSettings> alarms;

  /// Selected date and time for alarms.
  late DateTime selectedDateTime;

  /// Whether to loop audio for alarms.
  late bool loopAudio;

  /// Whether to vibrate for alarms.
  late bool vibrate;

  /// Volume level for alarms.
  late double? volume;

  /// Asset path for alarm audio.
  late String assetAudio;

  /// Body text for alarm notifications.
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
    bipaps = [];
    loadMedicines().then((loadedMedicines) {
      setState(() {
        medicines = loadedMedicines;
      });
    });
    loadBipap().then((loadedBipaps) {
      setState(() {
        bipaps = loadedBipaps;
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
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
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
                    _showSharePopup(context);
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
                  leading: const Icon(Icons.medication_liquid),
                  title: Text(Languages.of(context)!.addMedicine),
                  onTap: () {
                    _showAddMedicineDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_box_outlined),
                  title: Text(Languages.of(context)!.bipap),
                  onTap: () {
                    _showBipapDialog(context);
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
          body: provider.medicines.isNotEmpty
              ? MedicineTable(
                  medicines: provider.medicines,
                  onDeletePressed: (index) => provider.deleteMedicine(provider.medicines[index]),
                  onEditPressed: _showEditMedicineDialog,
                )
              : const Center(child: Text("No medicines added yet")),
        );
      },
    );
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
    List<Map<bool, String>> initialCheckboxStates =
        List.filled(1, {false: ""});
    DateTime creationDay = DateTime.now();
    creationDay =
        DateTime(creationDay.year, creationDay.month, creationDay.day);
    List<Map<DateTime, String>> dates = [];
    String dayName = DateFormat('EEEE').format(creationDay);
    dates.add({creationDay: dayName});

    final medicine = Medicine(
      time: time,
      name: medicineName,
      image: image,
      period: period,
      alarmId: alarmId,
      dates: dates,
      checkboxStates: initialCheckboxStates,
    );
    Provider.of<MedicineProvider>(context, listen: false).addMedicine(medicine);
  }

  void onEditMedicine(Medicine medicine, String updatedMedicineName,
      String selectedPeriod, Uint8List? imageBytes, DateTime selectedTime) {
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
    Provider.of<MedicineProvider>(context, listen: false).editMedicine(medicine);
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
    Uint8List? imageBytes;
    String period =
        Languages.of(context)!.timeOptions[0]; // Default selected time
    late DateTime time;
    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(Languages.of(context)!.addMedicine,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    onMedicineAdded(
                        medicineName, imageBytes, period, alarmId, time);
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
                            Provider.of<MedicineProvider>(context, listen: false).updateCheckbox(medicine, value!);
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
                              Provider.of<MedicineProvider>(context, listen: false).deleteMedicine(medicine);
                              Navigator.of(context).pop(); // Close the confirmation dialog
                              Navigator.of(context).pop(); // Close the edit dialog
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
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
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

  Future<void> _showSharePopup(BuildContext context) async {
    PDFCreator pdfCreator = PDFCreator();

    await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              Languages.of(context)!.sharePDF,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                final pdfFile = await pdfCreator.createPDF(
                      context,
                      loadMedicines(),
                      loadBiometrics(),
                      loadBipap(),
                      loadPersonal(),
                      true);
                  sharePdf(pdfFile);
                  Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.last10Days),
            ),ElevatedButton(
              onPressed: () async {
                final pdfFile = await pdfCreator.createPDF(
                      context,
                      loadMedicines(),
                      loadBiometrics(),
                      loadBipap(),
                      loadPersonal(),
                      false);
                  sharePdf(pdfFile);
                  Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.allData),
            ),
          ],
          );
        });
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
                personals = [personal];

                // personals.add(personal);
                await savePersonal(personals!);
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

  Future<void> _showBipapDialog(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime measurementDate = DateTime(now.year, now.month, now.day);

    double? bipap;

    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            Languages.of(context)!.enterBipap,
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),keyboardType: TextInputType.number,
                    onChanged: (value) {
                      bipap = double.tryParse(value);
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
                // print(bipap);
                // print(measurementDate);
                Bipap bipapVal =
                    Bipap(bipap: bipap, measurementDate: measurementDate);
                // Bipaps = [bipapVal];

                bipaps!.add(bipapVal);
                await saveBipap(bipaps!);
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


}

class AddMedicineWidget extends StatelessWidget {
  final void Function(String, String?, String) onMedicineAdded;

  const AddMedicineWidget({super.key, required this.onMedicineAdded});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 0);
  }
}
