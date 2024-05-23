import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'medicine.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MedicineTable extends StatefulWidget {
  final List<Medicine> medicines;
  // final Function(int, int, bool,String) onCheckboxChanged;
  final void Function(BuildContext, Medicine) onEditPressed; // Updated callback
  // final void Function(BuildContext, Medicine) onDaysEditPressed; // New callback
  // final void Function(BuildContext) onBiometrics; // New callback
  final Function(int) onDeletePressed;

  const MedicineTable({
    super.key,
    required this.medicines,
    // required this.onCheckboxChanged,
    required this.onEditPressed,
    // required this.onDaysEditPressed,
    // required this.onBiometrics,
    required this.onDeletePressed,
  });

  @override
  _MedicineTableState createState() => _MedicineTableState();
}

class _MedicineTableState extends State<MedicineTable> {
  Future<void> saveMedicines(List<Medicine> medicines) async {
    final Directory appDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final File file = File('${appDocumentsDirectory.path}/medicines.json');
    final List<dynamic> jsonList =
        medicines.map((medicine) => medicine.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  List<DataColumn> _buildColumns(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Define the width of each column as a fraction of the screen width
    double column1Width = screenWidth * 0.15;
    double column2Width = screenWidth * 0.35;
    double column3Width = screenWidth * 0.15;
    double column4Width = screenWidth * 0.15;
    double fontSize = 11;
    if (widget.medicines.isNotEmpty) {
      return [
        DataColumn(
            label: SizedBox(
          width: column1Width,
          child: Text(
            Languages.of(context)!.medicineColumn,
            style: TextStyle(
              fontSize: fontSize, // Adjust the font size as needed
            ),
          ),
        )),
        DataColumn(
            label: SizedBox(
          width: column2Width,
          child: Text(
            textAlign: TextAlign.center,
            Languages.of(context)!.imageColumn,
            style: TextStyle(
              fontSize: fontSize, // Adjust the font size as needed
            ),
          ),
        )),
        DataColumn(
            label: SizedBox(
          width: column3Width,
          child: Text(
            Languages.of(context)!.timeColumn,
            style: TextStyle(
              fontSize: fontSize, // Adjust the font size as needed
            ),
          ),
        )),
        DataColumn(
            label: SizedBox(
          width: column4Width,
          child: Text(
            '${Languages.of(context)!.currentDayName}\n ${Languages.of(context)!.currentDate}',
            style: TextStyle(
              fontSize: fontSize, // Adjust the font size as needed
            ),
          ),
        )),
      ];
    } else {
      return [
        const DataColumn(label: Text("")),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<Medicine>? medicines = widget.medicines;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              dataRowMaxHeight: 0,
              columnSpacing: 9,
              headingRowHeight: 50,
              columns: _buildColumns(context),
              rows: const []),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              dataRowMaxHeight: 100,
              columnSpacing: 0,
              headingRowHeight: 0,
              columns: _buildColumns(context),
              rows: List.generate(widget.medicines.length, (i) {
                Medicine medicine = widget.medicines[i];
                
                DateTime currentDay = DateTime.now();
                DateTime weekEnd =
                    medicine.creationDay.add(const Duration(days: 7));
                final currentDate = DateTime.now();
                final currentDayName = DateFormat(
                  'EEEE',
                ).format(currentDate);
                if (currentDay.isAfter(weekEnd)) {
                  int weeksPassed = 1;
                  medicine.creationDay = weekEnd;
                  weekEnd = weekEnd.add(Duration(days: 7 * weeksPassed));

                  for (int j = 0; j < 7 * weeksPassed; j++) {
                    String dayName = DateFormat(
                      'EEEE',
                    ).format(currentDay.add(Duration(days: j)));
                    String dateName = DateFormat('MM-dd')
                        .format(currentDay.add(Duration(days: j)));
                    medicine.dates.add({dateName: dayName});
                    medicine.checkboxStates
                        .add({false: ""}); // Default to false for new days
                  }
                  saveMedicines(medicines);
                }

                int displayDaysCount = 7;

                int start = medicine.dates.length > displayDaysCount
                    ? medicine.dates.length - displayDaysCount
                    : 0;
                List<Map<String, String>> lastDays =
                    medicine.dates.sublist(start);
                List<Map<bool, String>> lastCheckboxStates =
                    medicine.checkboxStates.sublist(start);
                List.from(medicine.checkboxStates);
                return DataRow(
                  onLongPress: () {
                    widget.onEditPressed(context, medicine);
                  },
                  cells: [
                    DataCell(
                      Container(
                        decoration:  BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: i <= widget.medicines.length-2 ?(  widget.medicines[i].time == widget.medicines[i+1].time ?  0 :3):0, // You can adjust the width as needed
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: screenWidth * 0.15,
                                maxWidth: screenWidth * 0.15,
                                minHeight: 50.0,
                                maxHeight: 150.0,
                              ),
                              child: AutoSizeText(
                                medicine.name,
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          border:  Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: i <= widget.medicines.length-2 ?(  widget.medicines[i].time == widget.medicines[i+1].time ?  0 :3):0 // You can adjust the width as needed
                            ),
                          ),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: medicine.imagePath != null
                                ? FileImage(File(medicine.imagePath!))
                                : const AssetImage('assets/1.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        decoration:  BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: i <= widget.medicines.length-2 ?(  widget.medicines[i].time == widget.medicines[i+1].time ?  0 :3):0 // You can adjust the width as needed
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Text(medicine.time),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ...[
                      for (int j = 0; j < 7; j++)
                        if (lastDays[j][lastDays[j].keys.first] ==
                            currentDayName)
                          DataCell(
                            Container(decoration:  BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: i <= widget.medicines.length-2 ?(  widget.medicines[i].time == widget.medicines[i+1].time ?  0 :3):0 // You can adjust the width as needed
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                              child: Center(
                                child: Checkbox(
                                    value: lastCheckboxStates[j].keys.first,
                                    onChanged: (value) {
                                      setState(() {
                                        Map<bool, String> mapAtIndex =
                                            Map.from(lastCheckboxStates[j]);
                                        mapAtIndex.remove(mapAtIndex.keys.first);
                                        mapAtIndex[value!] = DateFormat('hh:mm a')
                                            .format(DateTime.now());
                                        lastCheckboxStates[j] = mapAtIndex;
                                        for (int i = 0;
                                            i < lastDays.length;
                                            i++) {
                                          medicine.checkboxStates[start + i] =
                                              lastCheckboxStates[i];
                                        }
                                        saveMedicines(medicines);
                                      });
                                    }),
                              ),
                            ),
                          )
                    ]
                  ],
                );
              }),
            ),
          ),
        )
      ],
    );
  }
}
