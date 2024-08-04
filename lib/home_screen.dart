// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicine_tracker/classes_handler.dart';
import 'medicine.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MedicineTable extends StatefulWidget {
  final List<Medicine> medicines;
  final void Function(BuildContext, Medicine) onEditPressed; // Updated callback
  final Function(int) onDeletePressed;

  const MedicineTable({
    super.key,
    required this.medicines,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  _MedicineTableState createState() => _MedicineTableState();
}

class _MedicineTableState extends State<MedicineTable> {
  Border rowBorder(int i) {
    return Border(
      bottom: BorderSide(
        color: Colors.black,
        width: i <= widget.medicines.length - 2
            ? (widget.medicines[i].period == widget.medicines[i + 1].period
                ? 0
                : 5)
            : 0, // You can adjust the width as needed
      ),
    );
  }

  Text headerText(int columnIndex) {
    double headerfontSize = 13;
    final columnHeaders = [
      Languages.of(context)!.medicineColumn,
      Languages.of(context)!.imageColumn,
      Languages.of(context)!.timeColumn,
      '${Languages.of(context)!.currentDayName}\n ${Languages.of(context)!.currentDate}'
    ];

    return Text(
      columnHeaders[columnIndex],
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: headerfontSize,
          fontWeight: FontWeight.bold // Adjust the font size as needed
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<Medicine>? medicines = widget.medicines;
    double column1Width = screenWidth * 0.2;
    double column2Width = screenWidth * 0.4;
    double column3Width = screenWidth * 0.2;
    double column4Width = screenWidth * 0.2;

    return medicines.isNotEmpty
        ? Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: column1Width,
                    height: 50,
                    child: Center(
                      child: headerText(0),
                    ),
                  ),
                  SizedBox(
                    width: column2Width,
                    height: 50,
                    child: Center(
                      child: headerText(1),
                    ),
                  ),
                  SizedBox(
                    width: column3Width,
                    height: 50,
                    child: Center(
                      child: headerText(2),
                    ),
                  ),
                  SizedBox(
                    width: column4Width,
                    height: 50,
                    child: Center(
                      child: headerText(3),
                    ),
                  )
                ],
              ),
              Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.medicines.length,
                    itemBuilder: (context, i) {
                      Medicine medicine = widget.medicines[i];
                      DateTime currentDay = DateTime.now();
                      DateTime lastDay = medicine.dates.last.keys.last;

                      int deltaDay = currentDay
                          .difference(medicine.dates.last.keys.last)
                          .inDays;
                      if (deltaDay != 0) {
                        for (int j = 1; j <= deltaDay; j++) {
                          DateTime dateName = lastDay.add(Duration(days: j));
                          String dayName = DateFormat(
                            'EEEE',
                          ).format(dateName);
                          medicine.dates.add({dateName: dayName});
                          medicine.checkboxStates.add(
                              {false: ""}); // Default to false for new days
                        }
                        saveMedicines(medicines);
                      }
                      return GestureDetector(
                          onLongPress: () {
                            widget.onEditPressed(context, medicine);
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: column1Width,
                                height: 100,
                                child: Container(
                                  decoration:
                                      BoxDecoration(border: rowBorder(i)),
                                  alignment: Alignment.center,
                                  child: 
                                      Center(
                                            child: AutoSizeText(
                                              medicine.name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                            ),
                                          ),
                                   
                                ),
                              ),
                              SizedBox(
                                width: column2Width,
                                height: 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: rowBorder(i),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: medicine.image != null
                                          ? MemoryImage(medicine.image!)
                                          : const AssetImage('assets/1.png')
                                              as ImageProvider,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: column3Width,
                                height: 100,
                                child: Container(
                                  decoration:
                                      BoxDecoration(border: rowBorder(i)),
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8, top: 8),
                                    child: Column(
                                      children: [
                                        Text(medicine.period,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 12.0)),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8.0, bottom: 4),
                                          child: Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top:8.0),
                                          child: Text(
                                              DateFormat('hh:mm a')
                                                  .format(medicine.time),
                                              style:
                                                  const TextStyle(fontSize: 12.0)),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: column4Width,
                                height: 100,
                                child: Container(
                                  decoration:
                                      BoxDecoration(border: rowBorder(i)),
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: Checkbox(
                                        value: medicine
                                            .checkboxStates.last.keys.first,
                                        onChanged: !medicine
                                                .checkboxStates.last.keys.first
                                            ? (value) {
                                                setState(() {
                                                  // print("************");
                                                  Map<bool, String> mapAtIndex =
                                                      Map.from(medicine
                                                          .checkboxStates.last);
                                                  mapAtIndex.remove(
                                                      mapAtIndex.keys.first);
                                                  mapAtIndex[value!] = value ==
                                                          true
                                                      ? DateFormat('hh:mm a')
                                                          .format(
                                                              DateTime.now())
                                                      : "";
                                                  medicine.checkboxStates.last =
                                                      mapAtIndex;
                                                  saveMedicines(medicines);
                                                });
                                              }
                                            : null),
                                  ),
                                ),
                              )
                            ],
                          ));
                    }),
              ),
            ],
          )
        : const Text("");
  }
}
