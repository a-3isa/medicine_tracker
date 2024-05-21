import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'medicine.dart';
import 'package:medicine_tracker/language/language.dart';

class MedicineTable extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(int, int, bool) onCheckboxChanged;
  final void Function(BuildContext, Medicine) onEditPressed; // Updated callback
  // final void Function(BuildContext, Medicine) onDaysEditPressed; // New callback
  // final void Function(BuildContext) onBiometrics; // New callback
  final Function(int) onDeletePressed;

  const MedicineTable({
    super.key,
    required this.medicines,
    required this.onCheckboxChanged,
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
    return 
        SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: DataTable(
            dataRowMaxHeight: 100,
            columnSpacing: 10,
            headingRowHeight: 40,
            columns: _buildColumns(context),
            rows: List.generate(widget.medicines.length, (i) {
              List<Medicine>? medicines = widget.medicines;
          
              final medicine = widget.medicines[i];
              DateTime currentDay = DateTime.now();
              DateTime weekEnd =
                  medicine.creationDay.add(const Duration(days: 7));
              final currentDate = DateTime.now();
              final currentDayName = DateFormat(
                'EEEE',
              ).format(currentDate);
              // Update the creationDay if the current day is after the weekEnd
              if (currentDay.isAfter(weekEnd)) {
                int weeksPassed = 1;
                medicine.creationDay = weekEnd;
                weekEnd = weekEnd.add(Duration(days: 7 * weeksPassed));
          
                // Extend the lists to accommodate new unchecked days up to the current day
                for (int j = 0; j < 7 * weeksPassed; j++) {
                  medicine.days.add(DateFormat(
                    'EEEE',
                  ).format(currentDay.add(Duration(days: j))));
                  medicine.dates.add(DateFormat('MM-dd')
                      .format(currentDay.add(Duration(days: j))));
                  medicine.hours.add("");
                  medicine.checkboxStates
                      .add(false); // Default to false for new days
                }
              }
          
              int displayDaysCount = 7;
          
              int start = medicine.days.length > displayDaysCount
                  ? medicine.days.length - displayDaysCount
                  : 0;
              List<String> lastDays = medicine.days.sublist(start);
              List<String> lastHours = medicine.hours.sublist(start);
              List<bool> lastCheckboxStates =
                  medicine.checkboxStates.sublist(start);
              List.from(medicine.checkboxStates);
              return DataRow(
                onLongPress: () {
                  widget.onEditPressed(context, medicine);
                },
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Text(medicine.name),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
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
                  ...[
                    for (int j = 0; j < 7; j++)
                      if (lastDays[j] == currentDayName)
                        DataCell(
                          Row(
                            children: [
                              Checkbox(
                                  value: lastCheckboxStates[j],
                                  onChanged: (value) {
                                    setState(() {
                                      lastHours[j] = DateFormat('hh:mm a')
                                          .format(DateTime.now());
                                      // print(lastHours[j]);
                                      lastCheckboxStates[j] = value!;
                                      for (int i = 0; i < lastDays.length; i++) {
                                        medicine.checkboxStates[start + i] =
                                            lastCheckboxStates[i];
                                        medicine.hours[start + i] = lastHours[i];
                                      }
                                      saveMedicines(medicines);
                                    });
                                  }),
                            ],
                          ),
                        )
                  ]
                ],
              );
            }),
          ),
        );
      
    
  }
}
