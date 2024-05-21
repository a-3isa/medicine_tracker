import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import the date_symbol_data_local library
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;


void main() async {
  await initializeDateFormatting('ar'); // Initialize Arabic locale data

  runApp(const MedicineTableApp());
}

class MedicineTableApp extends StatelessWidget {
  const MedicineTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MedicineTablePage(),
    );
  }
}

class Medicine {
  String name;
  String? imagePath;
  String time;
  List<String> days;
  List<String> dates;
  List<bool> checkboxStates;

  Medicine({
    required this.name,
    this.imagePath,
    required this.time,
    required this.checkboxStates,
    required this.days,
    required this.dates,
  });

  Map<String, String> arabicToEnglishDay = {
    "الأحد": "Sunday",
    "الاثنين": "Monday",
    "الثلاثاء": "Tuesday",
    "الأربعاء": "Wednesday",
    "الخميس": "Thursday",
    "الجمعة": "Friday",
    "السبت": "Saturday"
  };
  String convertArabicDayToEnglish(String arabicDay) {
    return arabicToEnglishDay[arabicDay] ?? "Unknown";
  }

  @override
  String toString() {
    // Ensure days, dates, and checkboxStates have the same length
    assert(
        days.length == dates.length && dates.length == checkboxStates.length);

    // Using StringBuffer to build the string efficiently
    StringBuffer sb = StringBuffer();
    sb.write('name: $name, time: $time :');

    // Loop over the days, dates, and checkboxStates together
    for (int i = 0; i < days.length; i++) {
    String englishDay = convertArabicDayToEnglish(days[i]);

      sb.write(
          '\n$englishDay (${dates[i]}): ${checkboxStates[i] ? "Checked" : "Not Checked"} ');
    }

    // Remove the last comma and space, then close the bracket
    String result = sb.toString();
    if (days.isNotEmpty) {
      result = result.substring(
          0, result.length - 2); // Removing the last comma and space
    }

    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'checkboxStates': checkboxStates,
      'days': days,
      'dates': dates,
      'time': time,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      imagePath: json['imagePath'],
      time: json['time'],
      checkboxStates: List<bool>.from(json['checkboxStates'] as List),
      days: List<String>.from(json['days'] as List),
      dates: List<String>.from(json['dates'] as List),
    );
  }
}

class PDFCreator {
  static  Future<pw.Font> loadFont() async {
  final fontData = await rootBundle.load('assets/NotoSans-Regular.ttf');
  return pw.Font.ttf(fontData);
}
  static Future<File> createPDF(Future<List<Medicine>> futureItems) async {
    final pdf = pw.Document();
    final items = await futureItems;
    pw.TextStyle customStyle = pw.TextStyle(font: await loadFont());

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        children: items.map((item) => pw.Text(item.toString(),style: customStyle)).toList(),
      ); // Convert each item in the list to a Text widget
    }));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/my_document.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

}

void sharePdf(File pdfFile) async {
  print(pdfFile.path);
  Share.shareFiles([pdfFile.path], text: 'Here is the PDF file of the medicines.');
}

class MedicineTablePage extends StatefulWidget {
  const MedicineTablePage({super.key});

  @override
  _MedicineTablePageState createState() => _MedicineTablePageState();
}

class _MedicineTablePageState extends State<MedicineTablePage> {
  List<Medicine>? medicines;

  @override
  void initState() {
    super.initState();
    medicines = [];
    loadMedicines().then((loadedMedicines) {
      setState(() {
        medicines = loadedMedicines;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Table'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save_alt_sharp),
            onPressed: () async {
              final pdfFile =await PDFCreator.createPDF(loadMedicines());
              sharePdf(pdfFile);
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
                      onDaysEditPressed: _showDaysEditPopup,
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
      final currentDate = DateTime.now();
      List<String> days = [];
      List<String> dates = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = currentDate.add(Duration(days: i));
        String dayName = DateFormat('EEEE', 'ar').format(date);
        days.add(dayName);
        dates.add('${date.day}/${date.month}');
      }

      final medicine = Medicine(
        name: medicineName,
        imagePath: imagePath,
        time: time,
        days: days,
        dates: dates,
        checkboxStates: initialCheckboxStates,
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
    final timeOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];
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
    String time = 'Morning'; // Default selected time

    await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Medicine'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    hintText: 'Enter medicine name',
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
                  child: const Text('Select Image'),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: time,
                  onChanged: (String? newValue) {
                    setState(() {
                      time = newValue!;
                    });
                  },
                  items: const <String>[
                    'Morning',
                    'Afternoon',
                    'Evening',
                    'Night'
                  ].map<DropdownMenuItem<String>>((String value) {
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
                child: const Text('Cancel'),
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
                child: const Text('Add'),
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
            title: const Text('Edit Medicine'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    hintText: 'Enter medicine name',
                  ),
                ),
                const SizedBox(height: 20),
                selectedImage != null
                    ? Image.file(
                        selectedImage!,
                        height: 100,
                      )
                    : const Text("No image selected"),
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
                  child: const Text('Select Image'),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedTime,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTime = newValue!;
                    });
                  },
                  items: const <String>[
                    'Morning',
                    'Afternoon',
                    'Evening',
                    'Night'
                  ].map<DropdownMenuItem<String>>((String value) {
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
                        title: const Text('Confirm Delete'),
                        content: const Text(
                            'Are you sure you want to delete this medicine?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                onDeletePressed(medicine);
                              });
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Delete'),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDaysEditPopup(
      BuildContext context, Medicine medicine) async {
    final List<bool> originalCheckboxStates =
        List.from(medicine.checkboxStates);

    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Days'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < medicine.checkboxStates.length; i++)
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  final currentDate = DateTime.now();
                  final currentDateName =
                      DateFormat('EEEE', 'ar').format(currentDate);

                  final formattedDate =
                      '${medicine.days[i]}\n ${medicine.dates[i]}';
                  return CheckboxListTile(
                    title: Text(formattedDate),
                    value: medicine.checkboxStates[i],
                    onChanged: medicine.days[i] == currentDateName
                        ? (medicine.checkboxStates[i] == false
                            ? (value) {
                                setState(() {
                                  medicine.checkboxStates[i] = value!;
                                });
                              }
                            : null)
                        : null,
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                medicine.checkboxStates = originalCheckboxStates;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              saveMedicines(medicines!);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
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

class MedicineTable extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(int, int, bool) onCheckboxChanged;
  final void Function(BuildContext, Medicine) onEditPressed; // Updated callback
  final void Function(BuildContext, Medicine) onDaysEditPressed; // New callback
  final Function(int) onDeletePressed;

  const MedicineTable({
    super.key,
    required this.medicines,
    required this.onCheckboxChanged,
    required this.onEditPressed,
    required this.onDaysEditPressed,
    required this.onDeletePressed,
  });

  @override
  _MedicineTableState createState() => _MedicineTableState();
}

class _MedicineTableState extends State<MedicineTable> {
  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowHeight: 40,
      columns: const [
        DataColumn(label: Text('Medicine')),
        DataColumn(label: Text('Image')),
        DataColumn(label: Text('Time')), // Updated DataColumn for Time
      ],
      rows: List.generate(widget.medicines.length, (i) {
        final medicine = widget.medicines[i];
        return DataRow(
          cells: [
            DataCell(
              GestureDetector(
                onTap: () {
                  widget.onDaysEditPressed(context, medicine);
                },
                onLongPress: () {
                  widget.onEditPressed(context, medicine);
                },
                child: Row(
                  children: [
                    Text(medicine.name),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: medicine.imagePath != null
                        ? FileImage(File(medicine.imagePath!))
                        : const AssetImage('assets/1.png') as ImageProvider,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  Text(medicine.time),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
